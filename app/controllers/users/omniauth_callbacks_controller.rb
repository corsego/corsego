# frozen_string_literal: true

module Users
  class OmniauthCallbacksController < Devise::OmniauthCallbacksController
    skip_before_action :verify_authenticity_token, only: :google_onetap

    # Rate limit Google One Tap attempts: 10 attempts per 3 minutes per IP
    rate_limit to: 10, within: 3.minutes, only: :google_onetap, by: -> { request.remote_ip }

    def google_oauth2
      handle_auth 'Google'
    end

    def google_onetap
      # Verify CSRF token from Google
      unless valid_google_csrf_token?
        redirect_to root_path, alert: 'Invalid CSRF token'
        return
      end

      # Verify the JWT credential
      payload = verify_google_id_token(params[:credential])
      unless payload
        redirect_to root_path, alert: 'Invalid Google credential'
        return
      end

      @user = User.from_google_onetap(payload)
      if @user.persisted?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: 'Google'
        sign_in_and_redirect @user, event: :authentication
      else
        redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      end
    end

    def github
      handle_auth 'Github'
    end

    def facebook
      handle_auth 'Facebook'
    end

    def handle_auth(kind)
      @user = User.from_omniauth(request.env['omniauth.auth'])
      if @user.persisted?
        flash[:notice] = I18n.t 'devise.omniauth_callbacks.success', kind: kind
        sign_in_and_redirect @user, event: :authentication
      else
        session['devise.google_data'] = request.env['omniauth.auth'].except(:extra) # Removing extra as it can overflow some session stores
        redirect_to new_user_registration_url, alert: @user.errors.full_messages.join("\n")
      end
    end

    def failure
      redirect_to root_path, alert: 'Failure. Please try again'
    end

    private

    def valid_google_csrf_token?
      cookies['g_csrf_token'].present? &&
        params[:g_csrf_token].present? &&
        cookies['g_csrf_token'] == params[:g_csrf_token]
    end

    def verify_google_id_token(credential)
      return nil if credential.blank?

      client_id = Rails.application.credentials.dig(:google_oauth2, :id)
      Google::Auth::IDTokens.verify_oidc(credential, aud: client_id)
    rescue Google::Auth::IDTokens::VerificationError => e
      Rails.logger.error "Google ID token verification failed: #{e.message}"
      nil
    end
  end
end
