class AdminController < ApplicationController
  before_action :set_user, only: [:suspend_user]

  def admin_page
    @users = User.all.includes(:premium_user) # Include associazione per evitare query N+1
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
end
