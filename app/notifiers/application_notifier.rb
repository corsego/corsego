# frozen_string_literal: true

class ApplicationNotifier < Noticed::Event
  # Customize notification_methods, required_params, and other global settings here
  # This is the base class for all notifiers in the application

  def url
    nil
  end
end
