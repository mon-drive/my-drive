class ApplicationController < ActionController::Base
    helper_method :current_user
    protect_from_forgery with: :exception

    private

    def current_user
      @current_user ||= User.find(session[:user_id]) if session[:user_id]
    end
  end
