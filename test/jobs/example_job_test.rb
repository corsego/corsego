# frozen_string_literal: true

require "test_helper"

class ExampleJobTest < ActiveJob::TestCase
  test "job can be enqueued" do
    assert_enqueued_with(job: ExampleJob) do
      ExampleJob.perform_later("test message")
    end
  end

  test "job performs with default message" do
    result = ExampleJob.perform_now
    assert_equal "Hello from ExampleJob", result
  end

  test "job performs with custom message" do
    result = ExampleJob.perform_now("Custom message")
    assert_equal "Custom message", result
  end

  test "job is queued to default queue" do
    assert_equal "default", ExampleJob.new.queue_name
  end
end
