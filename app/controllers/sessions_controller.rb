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
    delete_all_items
    premium = PremiumUser.find_by(user: current_user)
    make = MakeTransaction.where(user: current_user)
    make.each do |m|
      pay_id = m.pay_transaction.id
      m.destroy
      PayTransaction.find(pay_id).destroy
    end
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

  private

  def delete_all_items
    possess = Possess.where(user_id: current_user.id)
    possess.each do |item|
      folder = UserFolder.find_by(id: item.user_folder_id)
      contains = Contains.where(user_folder_id: folder.id)
      contains.each do |contain|
        file = UserFile.find_by(id: contain.user_file_id)
        hasOwner = HasOwner.where(item: file.id)
        hasParent = HasParent.where(item_id: file.id)
        hasPermission = HasPermission.where(item_id: file.id)
        shareFile = ShareFile.where(user_file_id: file.id)
        hasOwner.each do |owner|
          owner.destroy
        end
        hasParent.each do |parent|
          parent.destroy
        end
        hasPermission.each do |permission|
          if permission.item_type == 'UserFile'
            permission.destroy
          end
        end
        shareFile.each do |share|
          share.destroy
        end
        contain.destroy
        file.destroy
      end
      if folder
        possesses = Possess.find_by(user_folder_id: folder.id)
        parent = Parent.find_by(itemid: folder.user_folder_id)
        hasParent = HasParent.where(parent_id: parent.id)
        hasOwner = HasOwner.where(item: folder.id)
        hasPermission = HasPermission.where(item_id: folder.id)
        shareFolder = ShareFolder.where(user_folder_id: folder.id)
        hasParent.each do |p|
          p.destroy
        end
        if possesses
          possesses.destroy
        end
        if parent
          parent.destroy
        end
        hasOwner.each do |owner|
          owner.destroy
        end
        hasPermission.each do |permission|
          if permission.item_type == 'UserFolder'
            permission.destroy
          end
        end
        shareFolder.each do |share|
          share.destroy
        end
        folder.destroy
      end
    end
  end
end
