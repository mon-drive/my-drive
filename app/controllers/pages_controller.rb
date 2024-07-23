class PagesController < ApplicationController
  before_action :authenticate_user, only: [:payment_complete, :process_payment]

  def pricing
    # logica per la pagina di pricing, se necessaria
  end

  def payment
    @plan = params[:plan]
    if @plan.nil?
      redirect_to pricing_path, alert: 'Nessun piano selezionato.'
    end
  end

  def payment_complete
    token = params[:stripeToken]
    amount = params[:amount].to_i

    begin
      charge = Stripe::Charge.create({
        amount: amount,
        currency: 'eur',
        description: 'Pagamento mensile',
        source: token,
      })

      flash[:notice] = "Pagamento effettuato con successo!"
    rescue Stripe::CardError => e
      flash[:alert] = e.message
    end

    redirect_to root_path

  end

  private

  def authenticate_user
    # Here you can check if the user is authenticated, e.g., by checking session or current_user
    redirect_to root_path, notice: 'Sei già loggato.' if session[:user_id].present?
  end

  def create_real_charge(token, amount)
    begin
      charge = Stripe::Charge.create({
        amount: amount, # Amount in cents
        currency: 'eur',
        source: token,
        description: 'MyDrive Payment',
      })
      charge
    rescue Stripe::CardError => e
      # The card has been declined
      Rails.logger.error "Stripe error: #{e.message}"
      nil
    end
  end
end
