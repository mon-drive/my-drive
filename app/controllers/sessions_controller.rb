class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:create]

    def create
      begin
        auth = request.env['omniauth.auth']
        user = User.from_omniauth(auth)
        session[:user_id] = user.id
        user.update_column(:profile_picture, auth.info.image)
        redirect_to dashboard_path
      rescue OmniAuth::Strategies::OAuth2::CallbackError => e
        redirect_to root_path, alert: "Access denied: #{e.error_reason}. Please try again."
      end
    end

    def destroy
      session[:user_id] = nil
      redirect_to root_path
    end

    def delete_account
      current_user.destroy
      session[:user_id] = nil
      respond_to do |format|
        format.json { render json: { success: true, message: 'Account eliminato con successo.' } }
      end
    end

    def auth_failure
      redirect_to root_path
    end
  end
