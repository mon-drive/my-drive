class SessionsController < ApplicationController
    skip_before_action :verify_authenticity_token, only: [:create]

    def create
      auth = request.env['omniauth.auth']
      user = User.from_omniauth(auth)
      session[:user_id] = user.id
      session[:image] = auth.info.image
      redirect_to dashboard_path
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
