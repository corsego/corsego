# frozen_string_literal: true

Rails.application.configure do
  # GoodJob configuration
  # https://github.com/bensheldon/good_job

  # Execute jobs immediately in the same process (inline mode)
  # Other options: :async, :external, :async_server
  config.good_job.execution_mode = :inline

  # Preserve job records for inspection in the dashboard
  config.good_job.preserve_job_records = true

  # Enable cron-style scheduled jobs (if needed in future)
  config.good_job.enable_cron = false

  # Dashboard configuration
  config.good_job.dashboard_default_locale = :en
end

# Authentication is handled via Devise in routes.rb:
# authenticate :user, ->(user) { user.has_role?(:admin) } do
#   mount GoodJob::Engine, at: "/good_job"
# end
