# frozen_string_literal: true

require "prawn"

class CertificatePdfGenerator
  PURPLE = "563d7c"

  def initialize(enrollment, base_url:, full_path:)
    @enrollment = enrollment
    @base_url = base_url
    @full_path = full_path
  end

  def generate
    Prawn::Document.new(page_size: "A4", page_layout: :landscape) do |pdf|
      draw_border(pdf)
      draw_content(pdf)
    end.render
  end

  private

  def draw_border(pdf)
    # Outer border
    pdf.stroke_color PURPLE
    pdf.line_width = 10
    pdf.stroke_rectangle [0, pdf.bounds.top], pdf.bounds.width, pdf.bounds.height

    # Inner border
    pdf.line_width = 5
    pdf.stroke_rectangle [20, pdf.bounds.top - 20], pdf.bounds.width - 40, pdf.bounds.height - 40
  end

  def draw_content(pdf)
    pdf.fill_color "000000"

    pdf.move_down 60

    # Title
    pdf.font_size 42
    pdf.text "Certificate of Completion", align: :center, style: :bold

    pdf.move_down 50

    # Body text
    pdf.font_size 16
    pdf.text "This is to certify that the owner of the email address", align: :center

    pdf.move_down 15

    # User email
    pdf.font_size 22
    pdf.text @enrollment.user.email, align: :center, style: :bold_italic

    pdf.move_down 15

    pdf.font_size 16
    pdf.text "has successfully completed the course", align: :center

    pdf.move_down 15

    # Course title
    pdf.font_size 22
    pdf.text @enrollment.course.title, align: :center, style: :bold_italic

    pdf.move_down 15

    pdf.font_size 16
    pdf.text "on the Corsego.com platform", align: :center

    pdf.move_down 50

    # Certificate details
    pdf.font_size 11
    pdf.text "Certificate ID: #{@enrollment.slug}", align: :center

    pdf.move_down 8

    pdf.text "Certificate URL: #{@base_url}#{@full_path}", align: :center

    pdf.move_down 8

    pdf.text "Registration date: #{@enrollment.created_at.strftime('%d-%b-%Y')}", align: :center

    pdf.move_down 40

    # Footer
    pdf.font_size 14
    pdf.text "www.Corsego.com", align: :center, style: :bold
  end
end
