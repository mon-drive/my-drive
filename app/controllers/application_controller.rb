class ApplicationController < ActionController::Base
    helper_method :current_user
    protect_from_forgery with: :exception

    before_action :load_locale

    def change_locale
      if params[:locale]
        I18n.locale = params[:locale]
        session[:locale] = I18n.locale
      end
      head :ok # This will send a simple OK response to the AJAX request
    end

    private

    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end

    def load_locale
      I18n.locale = session[:locale] || I18n.default_locale
    end
  end