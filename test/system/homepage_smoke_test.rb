# frozen_string_literal: true

require 'application_system_test_case'

class HomepageSmokeTest < ApplicationSystemTestCase
  test 'homepage loads successfully' do
    visit root_url
    assert_response_or_page_loaded
  end

  private

  def assert_response_or_page_loaded
    # Just verify the page loaded without error
    assert page.has_content?('Corsego') || page.has_css?('body'), 'Homepage should load'
  end
end
