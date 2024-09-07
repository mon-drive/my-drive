class PagesController < ApplicationController
  before_action :authenticate_user, only: [:payment_complete]
  before_action :check_active_subscription, only: [:payment]

  def pricing
    # logica per la pagina di pricing, se necessaria
  end
  def payment
    @plan = params[:plan]
    @stripe_key = ENV['STRIPE_PUBLISHABLE_KEY']
    if @plan.nil?
      redirect_to pricing_path, alert: t('payment.nothing')
    end
  end
  def payment_complete
    plan = params[:plan]
    @user = current_user
    if plan == 'free'
      if session[:user_id].present?
        # User is logged in
        redirect_to root_path, notice: t('payment.logged')
      else
        # User is not logged in
        redirect_to '/auth/google_oauth2'
      end
    else #(premium)
      token = params[:stripeToken]
      begin
        charge = Stripe::Charge.create({
          amount: @plan == 'annual' ? 9900 : 999, # in cents
          currency: 'eur',
          description: 'Example charge',
          source: token,
        })
        #Payment was successful
        logger.info "Stripe charge was successful: #{charge.inspect}"
        if charge.amount == 9900
          PremiumUser.create(user: @user, expire_date: Date.today + 1.year)
        else
          PremiumUser.create(user: @user, expire_date: Date.today + 1.month)
        end
        redirect_to root_path, notice: t('payment.success')
      rescue Stripe::CardError => e
        flash[:error] = e.message
        redirect_to payment_path
      rescue => e
        logger.error "Stripe charge failed: #{e.message}"
        flash[:error] = t('payment.error')
        redirect_to payment_path
      end
    end
  end
  private

  def authenticate_user
    if params[:plan] == 'free' && session[:user_id].present?
      pu = PremiumUser.find_by(user_id: session[:user_id])
      if pu.nil? #user has no subscription
        redirect_to root_path, notice: t('payment.logged')
      elsif pu.expire_date > Date.today
        redirect_to root_path, notice: t('payment.subscribed')
      end
    end
    redirect_to '/auth/google_oauth2' unless session[:user_id].present?
    # If the plan is premium, do not redirect, allowing payment to proceed
  end

  def check_active_subscription 
    pu = PremiumUser.find_by(user_id: session[:user_id])
    logger.info "Checking subscription for user: #{pu.inspect}"
    if pu.nil?
      # User has no subscription
      logger.info "User has no subscription"
    elsif pu.expire_date > Date.today
      logger.info "User has an active subscription"
      redirect_to root_path, notice: t('payment.subscribed')
    end
  end

end
