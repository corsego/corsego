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

  def draw_corner_flourish(pdf, x, y, size, corner_index) # rubocop:disable Naming/MethodParameterName
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
      pdf.text 'Certificate of Completion', align: :center, character_spacing: 1

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

  def draw_star(pdf, center_x, center_y, radius)
    # Draw a 5-pointed star
    points = []
    5.times do |i|
      # Outer point
      outer_angle = (i * 72 - 90) * Math::PI / 180
      points << [center_x + radius * Math.cos(outer_angle), center_y + radius * Math.sin(outer_angle)]

      # Inner point (at 0.4 of radius for nice star shape)
      inner_angle = ((i * 72) + 36 - 90) * Math::PI / 180
      inner_radius = radius * 0.4
      points << [center_x + inner_radius * Math.cos(inner_angle), center_y + inner_radius * Math.sin(inner_angle)]
    end

    pdf.fill_color LIGHT_GOLD
    pdf.fill_polygon(*points)
  end

  def draw_body(pdf)
    pdf.bounding_box([80, pdf.bounds.top - 185], width: pdf.bounds.width - 160, height: 200) do # rubocop:disable Metrics/BlockLength
      pdf.fill_color CHARCOAL
      pdf.font 'Times-Roman'

      # Preamble
      pdf.font_size 13
      pdf.text 'This is to certify that', align: :center

      pdf.move_down 18

      # Recipient name and email - prominent display
      pdf.fill_color NAVY
      pdf.font 'Times-Roman', style: :bold_italic
      pdf.font_size 26
      if @enrollment.user.name.present?
        pdf.text @enrollment.user.name, align: :center
        pdf.move_down 4
        pdf.font 'Times-Roman', style: :italic
        pdf.fill_color CHARCOAL
        pdf.font_size 12
      end
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
    # Draw an elegant official seal with slight rotation effect
    seal_x = 95
    seal_y = 105
    outer_radius = 35
    inner_radius = 26
    rotation = -12 * Math::PI / 180 # Slight counter-clockwise rotation

    # Outer decorative ring with serrated edge
    pdf.stroke_color GOLD
    pdf.fill_color GOLD
    pdf.line_width = 2.5
    pdf.stroke_circle [seal_x, seal_y], outer_radius

    # Serrated/starburst edge effect
    24.times do |i|
      angle = (i * 15 * Math::PI / 180) + rotation
      inner_point = outer_radius - 3
      outer_point = outer_radius + 2
      x1 = seal_x + inner_point * Math.cos(angle)
      y1 = seal_y + inner_point * Math.sin(angle)
      x2 = seal_x + outer_point * Math.cos(angle)
      y2 = seal_y + outer_point * Math.sin(angle)
      pdf.line_width = 1.5
      pdf.stroke_line [x1, y1], [x2, y2]
    end

    # Middle decorative ring
    pdf.line_width = 1
    pdf.stroke_circle [seal_x, seal_y], outer_radius - 6

    # Inner circle
    pdf.line_width = 2
    pdf.stroke_circle [seal_x, seal_y], inner_radius

    # Innermost circle
    pdf.line_width = 0.5
    pdf.stroke_circle [seal_x, seal_y], inner_radius - 4

    # Small decorative dots between rings
    16.times do |i|
      angle = (i * 22.5 * Math::PI / 180) + rotation
      dot_x = seal_x + (outer_radius - 3) * Math.cos(angle)
      dot_y = seal_y + (outer_radius - 3) * Math.sin(angle)
      pdf.fill_circle [dot_x, dot_y], 1
    end

    # Seal text - all in gold
    pdf.fill_color GOLD
    pdf.font 'Helvetica', style: :bold

    # Draw rotated text by using transformation
    pdf.rotate(rotation * 180 / Math::PI, origin: [seal_x, seal_y]) do
      pdf.draw_text 'CORSEGO', at: [seal_x - 20, seal_y + 6], size: 8
      pdf.draw_text 'ACADEMY', at: [seal_x - 19, seal_y - 4], size: 7

      # Draw a 5-pointed star instead of Unicode character
      draw_star(pdf, seal_x, seal_y - 12, 6)
    end
  end

  def draw_qr_code(pdf)
    # Generate QR code for verification URL
    verification_url = "#{@base_url}#{@full_path}"
    qr = RQRCode::QRCode.new(verification_url, level: :m)

    # Position QR code next to the seal on the left
    qr_x = 150
    qr_y = 130
    qr_size = 55
    module_size = qr_size.to_f / qr.modules.length

    # Draw decorative frame around QR code
    frame_padding = 5
    pdf.stroke_color GOLD
    pdf.line_width = 1.5
    pdf.stroke_rectangle(
      [qr_x - frame_padding, qr_y + frame_padding],
      qr_size + (frame_padding * 2),
      qr_size + (frame_padding * 2)
    )

    # Draw QR code modules
    qr.modules.each_with_index do |row, row_index|
      row.each_with_index do |mod, col_index|
        next unless mod

        x = qr_x + (col_index * module_size)
        y = qr_y - (row_index * module_size)
        pdf.fill_color NAVY
        pdf.fill_rectangle [x, y], module_size, module_size
      end
    end

    # Label below QR code
    pdf.fill_color GOLD
    pdf.font 'Helvetica', style: :bold
    pdf.font_size 6
    pdf.draw_text 'SCAN TO VERIFY', at: [qr_x + 2, qr_y - qr_size - 12]
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
    # Draw signature using italic font
    pdf.fill_color NAVY
    pdf.font 'Times-Roman', style: :italic
    pdf.draw_text 'Yaroslav Shmarov', at: [start_x - 15, start_y - 18], size: 14
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
