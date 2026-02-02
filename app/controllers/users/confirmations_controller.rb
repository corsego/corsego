# frozen_string_literal: true

module Users
  class ConfirmationsController < Devise::ConfirmationsController
    private

    def after_confirmation_path_for(_resource_name, resource)
      sign_in(resource)
      root_path
    end
  end
end
