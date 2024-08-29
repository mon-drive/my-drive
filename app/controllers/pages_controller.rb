class PagesController < ApplicationController
  before_action :authenticate_user, only: [:payment_complete]

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
    else #(premium)
      # Logica per completare l'iscrizione, ad esempio:
      # - Aggiornare l'utente con il piano selezionato
      # - Inviare una conferma via email
      # - Eseguire altre azioni necessarie

      # Stripe logic
      token = params[:stripeToken]
      begin
        charge = Stripe::Charge.create({
          amount: @plan == 'annual' ? 9900 : 999, # in cents
          currency: 'eur',
          description: 'Example charge',
          source: token,
        })
        #Successful payment
        redirect_to root_path, notice: "Iscrizione completata con successo."
      rescue Stripe::CardError => e
        flash[:error] = e.message
        redirect_to payment_path
      rescue => e
        logger.error "Stripe charge failed: #{e.message}"
        flash[:error] = "Internal Server Error"
        redirect_to payment_path
      end
    end
  end
  private

  def authenticate_user
    if params[:plan] == 'free' && session[:user_id].present?
      redirect_to root_path, notice: 'Sei già loggato.'
    end
    # If the plan is premium, do not redirect, allowing payment to proceed
  end

end
