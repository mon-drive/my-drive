class AdminController < ApplicationController
  #before_action :authenticate_user!
  before_action :set_user, only: [:suspend_user]
  before_action :update_suspend
  before_action :check_admin

  def admin_page
    @users = User.includes(:premium_user)
  end

  # def authenticate_user!
  #   current_user
  # end

  def suspend_user
    end_of_day = (Time.current + params[:days].to_i.days).end_of_day
    if @user_sos.update(suspended: true, end_suspend: end_of_day)
      render json: { success: true }
    else
      render json: { success: false, errors: @user.errors.full_messages }, status: :unprocessable_entity
    end
  end

  private

  def set_user
    @user_sos = User.find(params[:id])
  end

  def check_admin
    unless current_user.admin_user.present?
      redirect_to root_path
    end
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
