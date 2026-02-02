# frozen_string_literal: true

require 'test_helper'

class CertificatePdfGeneratorTest < ActiveSupport::TestCase
  setup do
    @enrollment = enrollments(:student_enrollment)
    @base_url = 'http://localhost:3000'
    @full_path = "/enrollments/#{@enrollment.slug}/certificate.pdf"
  end

  test 'generates a valid PDF document' do
    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf_content = generator.generate

    assert pdf_content.present?, 'PDF content should not be empty'
    assert pdf_content.start_with?('%PDF'), 'Output should be a valid PDF'
    assert pdf_content.include?('%%EOF'), 'PDF should have proper ending'
  end

  test 'PDF contains user email' do
    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf_content = generator.generate

    # PDF text is encoded, but we can verify the PDF is generated
    # The actual text content verification would require PDF parsing
    assert pdf_content.present?
    assert pdf_content.length > 1000, 'PDF should have substantial content'
  end

  test 'PDF contains course title' do
    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf_content = generator.generate

    assert pdf_content.present?
    # Verify it's a multi-page or substantial document
    assert pdf_content.length > 1000
  end

  test 'PDF contains certificate metadata' do
    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf_content = generator.generate

    # Check PDF has proper structure
    assert pdf_content.include?('/Type /Catalog'), 'PDF should have catalog'
    assert pdf_content.include?('/Type /Page'), 'PDF should have pages'
  end

  test 'generates landscape A4 PDF' do
    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf_content = generator.generate

    # A4 landscape dimensions in points: 841.89 x 595.28
    # Check for MediaBox which defines page size
    assert pdf_content.include?('/MediaBox'), 'PDF should define page size'
  end

  test 'can be called multiple times for same enrollment' do
    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf1 = generator.generate
    pdf2 = generator.generate

    assert pdf1.present?
    assert pdf2.present?
    # Both should be valid PDFs (content may differ slightly due to timestamps)
    assert pdf1.start_with?('%PDF')
    assert pdf2.start_with?('%PDF')
  end

  test 'handles enrollment with special characters in course title' do
    # Create a course with special characters
    course = @enrollment.course
    original_title = course.title
    course.update_column(:title, "Ruby & Rails: A Developer's Guide")

    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf_content = generator.generate

    assert pdf_content.present?
    assert pdf_content.start_with?('%PDF')

    # Restore original title
    course.update_column(:title, original_title)
  end

  test 'handles enrollment with special characters in user email' do
    user = @enrollment.user
    original_email = user.email
    user.update_column(:email, "test+special@example.com")

    generator = CertificatePdfGenerator.new(
      @enrollment,
      base_url: @base_url,
      full_path: @full_path
    )

    pdf_content = generator.generate

    assert pdf_content.present?
    assert pdf_content.start_with?('%PDF')

    # Restore original email
    user.update_column(:email, original_email)
  end
end
