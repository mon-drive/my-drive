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
    plan = params[:plan]
    if plan == 'free'
      if session[:user_id].present?
        # User is logged in
        redirect_to root_path, notice: 'Sei già loggato.'
      else
        # User is not logged in
        redirect_to '/auth/google_oauth2'
      end
    else
      # Logica per completare l'iscrizione, ad esempio:
      # - Aggiornare l'utente con il piano selezionato
      # - Inviare una conferma via email
      # - Eseguire altre azioni necessarie

      # Redirect alla homepage o a una pagina di conferma
      redirect_to root_path, notice: "Iscrizione completata con successo."
    end
  end

  def process_payment
    token = params[:stripeToken]
    amount = params[:amount].to_i

    if token
      charge = create_real_charge(token, amount)
      if charge
        redirect_to root_path, notice: 'Payment was successfully processed.'
      else
        redirect_to root_path, alert: 'Payment failed. Please try again.'
      end
    else
      redirect_to root_path, alert: 'Payment failed. Please try again.'
    end
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
