class SessionsController < ApplicationController
  skip_before_action :verify_authenticity_token, only: [:create]

  def create
    auth = request.env['omniauth.auth']
    user = User.from_omniauth(auth)
    session[:user_id] = user.id
    user.update(logged_in: true)
    user.update_column(:profile_picture, auth.info.image)
    redirect_to dashboard_path
  end

  def destroy
    user = User.find(session[:user_id])
    user.update(logged_in: false) if user
    session.delete(:user_id)
    redirect_to root_path
  end

  def delete_account
    possess = Possess.where(user_id: current_user.id)
    possess.each do |poss|
    folder = UserFolder.find(poss.user_folder_id)
      contains = Contains.where(user_folder_id: folder.id)
      contains.each do |contain|
        file = UserFile.find_by(id: contain.user_file_id)
        shared = ShareFile.find_by(user_file_id: file.id)
        hasParent = HasParent.find_by(item_type: 'UserFile', item_id: file.id)
        owner = HasOwner.find_by(item: file.id)
        owner.destroy if owner
        hasParent.destroy if hasParent
        shared.destroy if shared
        contain.destroy
        file.destroy if file
      end
      shared = ShareFolder.find_by(user_folder_id: folder.id)
      hasParent = HasParent.find_by(item_type: 'UserFolder', item_id: folder.id)
      owner = HasOwner.find_by(item: folder.id)
      owner.destroy if owner
      hasParent.destroy if hasParent
      shared.destroy if shared
      poss.destroy
      folder.destroy
    end
    premium = PremiumUser.find_by(user: current_user)
    premium.destroy if premium
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
