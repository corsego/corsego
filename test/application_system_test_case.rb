# frozen_string_literal: true

require 'test_helper'

class ApplicationSystemTestCase < ActionDispatch::SystemTestCase
  driven_by :selenium, using: :headless_chrome, screen_size: [1400, 1400]

  # Increase default wait time to handle Turbo Drive transitions
  Capybara.default_max_wait_time = 5
end