# frozen_string_literal: true

require 'application_system_test_case'

class TomSelectSmokeTest < ApplicationSystemTestCase
  setup do
    @teacher = users(:teacher)
    @course = courses(:unpublished_course)
    @ruby_tag = tags(:ruby)
    @rails_tag = tags(:rails)
  end

  test 'tom-select initializes on course wizard targeting step' do
    sign_in @teacher
    visit course_course_wizard_path(@course, :targeting)

    # Tom-Select should initialize and create its wrapper element
    assert_selector '.ts-wrapper', wait: 5,
                    text: nil # Tom-Select creates a .ts-wrapper around the select

    # The original select should be hidden and replaced by Tom-Select
    assert_selector 'select[data-controller="tom-select"]', visible: :hidden
  end

  test 'tom-select allows selecting existing tags' do
    sign_in @teacher
    visit course_course_wizard_path(@course, :targeting)

    # Wait for Tom-Select to initialize
    assert_selector '.ts-wrapper', wait: 5

    # Click the Tom-Select input to open the dropdown
    find('.ts-control').click

    # The dropdown should show available tags
    assert_selector '.ts-dropdown-content .option', minimum: 1, wait: 5

    # Click to select a tag
    find('.ts-dropdown-content .option', text: @ruby_tag.name).click

    # The tag should appear as selected (in the control area as an item)
    assert_selector '.ts-control .item', text: @ruby_tag.name
  end

  test 'tom-select preserves selection on form submission' do
    sign_in @teacher
    visit course_course_wizard_path(@course, :targeting)

    # Wait for Tom-Select to initialize
    assert_selector '.ts-wrapper', wait: 5

    # Select a tag
    find('.ts-control').click
    find('.ts-dropdown-content .option', text: @ruby_tag.name).click

    # Submit the form
    click_button 'Save & Continue'

    # Verify we moved to the next step (pricing)
    assert_selector 'input[name="course[price]"]', wait: 10

    # Go back to targeting step to verify the tag was saved
    visit course_course_wizard_path(@course, :targeting)
    assert_selector '.ts-wrapper', wait: 5

    # The previously selected tag should still be selected
    assert_selector '.ts-control .item', text: @ruby_tag.name
  end

  test 'tom-select allows creating new tags' do
    sign_in @teacher
    visit course_course_wizard_path(@course, :targeting)

    # Wait for Tom-Select to initialize
    assert_selector '.ts-wrapper', wait: 5

    new_tag_name = "NewTestTag#{SecureRandom.hex(4)}"

    # Type a new tag name in the input
    find('.ts-control input').set(new_tag_name)

    # Tom-Select should show the create option
    assert_selector '.ts-dropdown-content .create', text: /#{new_tag_name}/i, wait: 5

    # Click to create the new tag
    find('.ts-dropdown-content .create').click

    # The new tag should appear as selected
    assert_selector '.ts-control .item', text: new_tag_name

    # Submit the form to persist
    click_button 'Save & Continue'

    # Verify the tag was created in the database
    assert Tag.exists?(name: new_tag_name), 'New tag should be created in the database'
  end
end
