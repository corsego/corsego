# frozen_string_literal: true

require 'application_system_test_case'

class StimulusSmokeTest < ApplicationSystemTestCase
  test 'stimulus controller connects and updates DOM' do
    visit root_url

    # The hello controller should connect and update the output target
    # from "Loading..." to "Stimulus is working!"
    stimulus_element = find('#stimulus-smoke-test span', visible: :all)

    assert_equal 'Stimulus is working!', stimulus_element.text,
                 'Stimulus hello controller should update the output target on connect'
  end
end
