# frozen_string_literal: true

require 'application_system_test_case'

class SelectizeSmokeTest < ApplicationSystemTestCase
  setup do
    @teacher = users(:teacher)
    @course = courses(:unpublished_course)
  end

  test 'selectize initializes on course wizard targeting page' do
    sign_in @teacher
    visit course_course_wizard_path(@course, :targeting)

    # Selectize transforms the select element and adds a wrapper div with
    # class 'selectize-control' containing an input with class 'selectize-input'
    assert_selector '.selectize-control', wait: 10,
                    text: nil # Just verify the element exists
    assert_selector '.selectize-input', wait: 5

    # The original select should be hidden but still in the DOM
    assert_selector 'select.selectize-tags', visible: :hidden
  end
end
