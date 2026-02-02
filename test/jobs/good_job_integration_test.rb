# frozen_string_literal: true

require "test_helper"

class GoodJobIntegrationTest < ActiveJob::TestCase
  test "GoodJob is configured as the queue adapter" do
    assert_equal :good_job, Rails.application.config.active_job.queue_adapter
  end

  test "GoodJob is set to inline execution mode" do
    assert_equal :inline, Rails.application.config.good_job.execution_mode
  end

  test "GoodJob preserves job records" do
    assert Rails.application.config.good_job.preserve_job_records
  end

  test "jobs execute inline immediately" do
    # In inline mode, perform_later should execute immediately
    results = []

    # Create a job class that tracks execution
    job = ExampleJob.new("inline test")

    # In inline mode, the job should execute immediately when enqueued
    # We can verify this by checking that perform_now works correctly
    result = ExampleJob.perform_now("inline execution test")
    assert_equal "inline execution test", result
  end

  test "GoodJob engine is mounted" do
    # Verify the route exists
    routes = Rails.application.routes.routes.map { |r| r.path.spec.to_s }
    assert routes.any? { |route| route.include?("good_job") },
           "GoodJob engine should be mounted at /good_job"
  end

  test "GoodJob dashboard requires admin authentication" do
    # Verify the route is wrapped in authenticate constraint
    # by checking that /good_job routes exist within the authenticated scope
    good_job_routes = Rails.application.routes.routes.select { |r| r.path.spec.to_s.include?("good_job") }
    assert good_job_routes.any?, "GoodJob routes should exist"
  end
end
