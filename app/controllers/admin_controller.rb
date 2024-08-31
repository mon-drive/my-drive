class AdminController < ApplicationController
  before_action :set_user, only: [:suspend_user]
  before_action :update_suspend

  def admin_page
    @users = User.where.not(id: current_user.id).includes(:premium_user) # Escludi l'utente corrente
  end

  def suspend_user
    if @user.update(suspended: true, end_suspend: Time.current + params[:days].to_i.days)
      render json: { success: true }
    else
      render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user = User.find(params[:id])
  end

  def update_suspend
    users = User.where.not(id: current_user.id).includes(:premium_user) # Escludi l'utente corrente
    for user in users
      if user.suspended==true and user.end_suspend!=nil and user.end_suspend < Time.now
        user.update(suspended: false, end_suspend: nil)
      end
    end
  end
end
