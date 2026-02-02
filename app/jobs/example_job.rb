# frozen_string_literal: true

class ExampleJob < ApplicationJob
  queue_as :default

  def perform(message = "Hello from ExampleJob")
    Rails.logger.info("[ExampleJob] #{message}")
    message
  end
end
