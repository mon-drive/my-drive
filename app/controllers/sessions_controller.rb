class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)
    session[:user_id] = user.id
    user.update_column(:profile_picture, auth.info.image)
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
    if params[:error] == 'access_denied'
      flash[:error] = "Accesso negato: non hai autorizzato l'accesso."
    else
      flash[:error] = "Si è verificato un errore durante l'autenticazione: #{params[:error_description]}"
    end
    redirect_to root_path
  end
end
