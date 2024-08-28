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
      @current_user ||= User.find_by(id: session[:user_id]) if session[:user_id]
      if @current_user
        @current_user
      else
        # /auth/google_oauth2
        redirect_to '/auth/google_oauth2' and return
      end
    end

    def load_locale
      I18n.locale = session[:locale] || I18n.default_locale
    end
  end
