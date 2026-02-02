# frozen_string_literal: true

require 'prawn'
require 'rqrcode'

class CertificatePdfGenerator
  # Elegant color palette
  GOLD = 'B8860B'
  DARK_GOLD = '8B7355'
  NAVY = '1a1a2e'
  CHARCOAL = '2d2d2d'
  LIGHT_GOLD = 'D4AF37'

  def initialize(enrollment, base_url:, full_path:)
    @enrollment = enrollment
    @base_url = base_url
    @full_path = full_path
  end

  def generate
    Prawn::Document.new(page_size: 'A4', page_layout: :landscape, margin: 0) do |pdf|
      draw_background(pdf)
      draw_decorative_border(pdf)
      draw_corner_ornaments(pdf)
      draw_header(pdf)
      draw_body(pdf)
      draw_seal(pdf)
      draw_qr_code(pdf)
      draw_signatures(pdf)
      draw_footer(pdf)
    end.render
  end

  private

  def draw_background(pdf)
    # Subtle cream/ivory background
    pdf.fill_color 'FFFEF5'
    pdf.fill_rectangle [0, pdf.bounds.top], pdf.bounds.width, pdf.bounds.height
  end

  def draw_decorative_border(pdf)
    margin = 25
    inner_margin = 35
    width = pdf.bounds.width
    height = pdf.bounds.height

    # Outer gold border
    pdf.stroke_color GOLD
    pdf.line_width = 3
    pdf.stroke_rectangle [margin, height - margin], width - (margin * 2), height - (margin * 2)

    # Middle thin line
    pdf.stroke_color DARK_GOLD
    pdf.line_width = 0.5
    pdf.stroke_rectangle [margin + 5, height - margin - 5], width - (margin * 2) - 10, height - (margin * 2) - 10

    # Inner border
    pdf.stroke_color GOLD
    pdf.line_width = 1.5
    pdf.stroke_rectangle [inner_margin, height - inner_margin], width - (inner_margin * 2), height - (inner_margin * 2)
  end

  def draw_corner_ornaments(pdf)
    pdf.stroke_color GOLD
    pdf.fill_color GOLD
    pdf.line_width = 1

    ornament_size = 20
    offset = 45

    corners = [
      [offset, pdf.bounds.top - offset],
      [pdf.bounds.width - offset, pdf.bounds.top - offset],
      [offset, offset],
      [pdf.bounds.width - offset, offset]
    ]

    corners.each_with_index do |(x, y), index|
      draw_corner_flourish(pdf, x, y, ornament_size, index)
    end
  end

  def draw_corner_flourish(pdf, x, y, size, corner_index)
    pdf.stroke_color GOLD
    pdf.line_width = 1.5

    # Draw elegant corner flourishes based on position
    case corner_index
    when 0 # Top-left
      pdf.stroke_line [x, y], [x + size, y]
      pdf.stroke_line [x, y], [x, y - size]
      pdf.fill_circle [x + 3, y - 3], 2
    when 1 # Top-right
      pdf.stroke_line [x, y], [x - size, y]
      pdf.stroke_line [x, y], [x, y - size]
      pdf.fill_circle [x - 3, y - 3], 2
    when 2 # Bottom-left
      pdf.stroke_line [x, y], [x + size, y]
      pdf.stroke_line [x, y], [x, y + size]
      pdf.fill_circle [x + 3, y + 3], 2
    when 3 # Bottom-right
      pdf.stroke_line [x, y], [x - size, y]
      pdf.stroke_line [x, y], [x, y + size]
      pdf.fill_circle [x - 3, y + 3], 2
    end
  end

  def draw_header(pdf)
    pdf.bounding_box([50, pdf.bounds.top - 50], width: pdf.bounds.width - 100, height: 120) do
      # Institution name
      pdf.fill_color NAVY
      pdf.font 'Helvetica', style: :bold
      pdf.font_size 14
      pdf.text 'CORSEGO ACADEMY', align: :center, character_spacing: 4

      pdf.move_down 8

      # Decorative line
      draw_decorative_divider(pdf, pdf.cursor)

      pdf.move_down 15

      # Certificate title
      pdf.font 'Times-Roman', style: :bold
      pdf.fill_color CHARCOAL
      pdf.font_size 38
      pdf.text 'Certificate of Completion', align: :center

      pdf.move_down 8

      # Subtitle
      pdf.font 'Times-Roman', style: :italic
      pdf.fill_color DARK_GOLD
      pdf.font_size 12
      pdf.text 'This document certifies the successful completion of studies', align: :center
    end
  end

  def draw_decorative_divider(pdf, y_position)
    center_x = pdf.bounds.width / 2
    line_width = 180

    pdf.stroke_color GOLD
    pdf.line_width = 0.75

    # Left line
    pdf.stroke_line [center_x - line_width, y_position], [center_x - 20, y_position]
    # Right line
    pdf.stroke_line [center_x + 20, y_position], [center_x + line_width, y_position]

    # Center diamond ornament
    pdf.fill_color GOLD
    diamond_size = 4
    pdf.fill_polygon(
      [center_x, y_position + diamond_size],
      [center_x + diamond_size, y_position],
      [center_x, y_position - diamond_size],
      [center_x - diamond_size, y_position]
    )
  end

  def draw_body(pdf)
    pdf.bounding_box([80, pdf.bounds.top - 185], width: pdf.bounds.width - 160, height: 200) do
      pdf.fill_color CHARCOAL
      pdf.font 'Times-Roman'

      # Preamble
      pdf.font_size 13
      pdf.text 'This is to certify that', align: :center

      pdf.move_down 18

      # Recipient name/email - prominent display
      pdf.fill_color NAVY
      pdf.font 'Times-Roman', style: :bold_italic
      pdf.font_size 26
      pdf.text @enrollment.user.email, align: :center

      pdf.move_down 18

      # Achievement text
      pdf.fill_color CHARCOAL
      pdf.font 'Times-Roman'
      pdf.font_size 13
      pdf.text 'has successfully completed all requirements for the course', align: :center

      pdf.move_down 18

      # Course title - elegant display
      pdf.fill_color NAVY
      pdf.font 'Times-Roman', style: :bold
      pdf.font_size 22
      pdf.text "\"#{@enrollment.course.title}\"", align: :center

      pdf.move_down 18

      # Platform attribution
      pdf.fill_color CHARCOAL
      pdf.font 'Times-Roman', style: :italic
      pdf.font_size 11
      pdf.text 'offered through the Corsego Academy online learning platform', align: :center
    end
  end

  def draw_seal(pdf)
    # Draw an official-looking seal on the left side
    seal_x = 130
    seal_y = 95
    outer_radius = 40
    inner_radius = 30

    # Outer circle
    pdf.stroke_color GOLD
    pdf.line_width = 2
    pdf.stroke_circle [seal_x, seal_y], outer_radius

    # Inner circle
    pdf.line_width = 1
    pdf.stroke_circle [seal_x, seal_y], inner_radius

    # Decorative dots around the seal
    12.times do |i|
      angle = i * 30 * Math::PI / 180
      dot_x = seal_x + (outer_radius - 5) * Math.cos(angle)
      dot_y = seal_y + (outer_radius - 5) * Math.sin(angle)
      pdf.fill_color GOLD
      pdf.fill_circle [dot_x, dot_y], 1.5
    end

    # Seal text
    pdf.fill_color NAVY
    pdf.font 'Helvetica', style: :bold
    pdf.draw_text 'CORSEGO', at: [seal_x - 22, seal_y + 8], size: 8
    pdf.draw_text 'VERIFIED', at: [seal_x - 18, seal_y - 5], size: 7
    pdf.fill_color GOLD
    pdf.draw_text '*', at: [seal_x - 4, seal_y - 18], size: 14
  end

  def draw_qr_code(pdf)
    # Generate QR code for verification URL
    verification_url = "#{@base_url}#{@full_path}"
    qr = RQRCode::QRCode.new(verification_url, level: :m)

    # Position QR code on the right side, mirroring the seal
    qr_x = pdf.bounds.width - 170
    qr_y = 135
    qr_size = 70
    module_size = qr_size.to_f / qr.modules.length

    # Draw decorative frame around QR code
    frame_padding = 8
    pdf.stroke_color GOLD
    pdf.line_width = 1.5
    pdf.stroke_rectangle(
      [qr_x - frame_padding, qr_y + frame_padding],
      qr_size + (frame_padding * 2),
      qr_size + (frame_padding * 2)
    )

    # Draw inner frame
    pdf.line_width = 0.5
    pdf.stroke_rectangle(
      [qr_x - frame_padding + 3, qr_y + frame_padding - 3],
      qr_size + (frame_padding * 2) - 6,
      qr_size + (frame_padding * 2) - 6
    )

    # Draw QR code modules
    qr.modules.each_with_index do |row, row_index|
      row.each_with_index do |mod, col_index|
        if mod
          x = qr_x + (col_index * module_size)
          y = qr_y - (row_index * module_size)
          pdf.fill_color NAVY
          pdf.fill_rectangle [x, y], module_size, module_size
        end
      end
    end

    # Label below QR code
    pdf.fill_color DARK_GOLD
    pdf.font "Helvetica", style: :bold
    pdf.font_size 7
    pdf.draw_text "SCAN TO VERIFY", at: [qr_x + 5, qr_y - qr_size - 15]
  end

  def draw_signatures(pdf)
    sig_y = 110
    left_sig_x = pdf.bounds.width / 2 - 60
    right_sig_x = pdf.bounds.width / 2 + 140

    pdf.fill_color CHARCOAL
    pdf.stroke_color CHARCOAL

    # Date of completion (left side, after seal)
    pdf.font 'Times-Roman'
    pdf.font_size 10
    completion_date = @enrollment.created_at.strftime('%B %d, %Y')

    # Left signature area - Date
    pdf.line_width = 0.5
    pdf.stroke_line [left_sig_x, sig_y], [left_sig_x + 120, sig_y]
    pdf.draw_text completion_date, at: [left_sig_x + 25, sig_y + 8], size: 11
    pdf.font 'Times-Roman', style: :italic
    pdf.draw_text 'Date of Completion', at: [left_sig_x + 20, sig_y - 15], size: 9

    # Right signature area - Director signature
    draw_signature(pdf, right_sig_x + 15, sig_y + 25)
    pdf.stroke_color CHARCOAL
    pdf.line_width = 0.5
    pdf.stroke_line [right_sig_x, sig_y], [right_sig_x + 120, sig_y]
    pdf.font 'Times-Roman', style: :italic
    pdf.draw_text 'Director of Education', at: [right_sig_x + 15, sig_y - 15], size: 9
  end

  def draw_signature(pdf, start_x, start_y)
    # Draw an elegant cursive signature using bezier curves
    # This creates a stylized "E. Morrison" signature
    pdf.stroke_color NAVY
    pdf.line_width = 0.8

    # Capital E with flourish
    pdf.stroke do
      # E vertical stroke
      pdf.move_to [start_x, start_y]
      pdf.curve_to [start_x + 2, start_y - 18],
                   bounds: [[start_x - 3, start_y - 6], [start_x - 2, start_y - 14]]

      # E top curve
      pdf.move_to [start_x, start_y]
      pdf.curve_to [start_x + 12, start_y - 2],
                   bounds: [[start_x + 4, start_y + 2], [start_x + 10, start_y + 1]]

      # E middle stroke
      pdf.move_to [start_x + 1, start_y - 9]
      pdf.curve_to [start_x + 10, start_y - 8],
                   bounds: [[start_x + 4, start_y - 7], [start_x + 8, start_y - 7]]

      # Period after E
      pdf.fill_color NAVY
      pdf.fill_circle [start_x + 14, start_y - 16], 0.8
    end

    # "Morrison" in flowing script
    m_start = start_x + 20

    pdf.stroke do
      # M - first hump
      pdf.move_to [m_start, start_y - 18]
      pdf.curve_to [m_start + 6, start_y - 5],
                   bounds: [[m_start, start_y - 12], [m_start + 3, start_y - 5]]
      pdf.curve_to [m_start + 12, start_y - 18],
                   bounds: [[m_start + 9, start_y - 5], [m_start + 12, start_y - 12]]

      # M - second hump
      pdf.move_to [m_start + 12, start_y - 18]
      pdf.curve_to [m_start + 18, start_y - 8],
                   bounds: [[m_start + 12, start_y - 12], [m_start + 15, start_y - 6]]
      pdf.curve_to [m_start + 24, start_y - 18],
                   bounds: [[m_start + 21, start_y - 6], [m_start + 24, start_y - 12]]

      # "orrison" - flowing continuation
      pdf.move_to [m_start + 24, start_y - 18]
      pdf.curve_to [m_start + 70, start_y - 16],
                   bounds: [[m_start + 35, start_y - 10], [m_start + 55, start_y - 22]]

      # Final flourish underline
      pdf.move_to [m_start + 70, start_y - 16]
      pdf.curve_to [m_start + 45, start_y - 22],
                   bounds: [[m_start + 65, start_y - 20], [m_start + 55, start_y - 24]]
    end
  end

  def draw_footer(pdf)
    pdf.bounding_box([50, 70], width: pdf.bounds.width - 100, height: 30) do
      # Certificate ID and verification info
      pdf.fill_color DARK_GOLD
      pdf.font 'Helvetica'
      pdf.font_size 7

      certificate_info = "Certificate ID: #{@enrollment.slug}  •  Verify at: #{@base_url}#{@full_path}"
      pdf.text certificate_info, align: :center

      pdf.move_down 3

      pdf.fill_color CHARCOAL
      pdf.font_size 6
      pdf.text 'This certificate validates the completion of the above-mentioned course. ' \
               'Verify authenticity by scanning the QR code or visiting the URL above.',
               align: :center
    end
  end
end
