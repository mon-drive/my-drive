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
    else
      # Logica per completare l'iscrizione, ad esempio:
      # - Aggiornare l'utente con il piano selezionato
      # - Inviare una conferma via email
      # - Eseguire altre azioni necessarie

      # Redirect alla homepage o a una pagina di conferma
      redirect_to root_path, notice: "Iscrizione completata con successo."
    end
  end

  private

  def authenticate_user
    # Here you can check if the user is authenticated, e.g., by checking session or current_user
    redirect_to root_path, notice: 'Sei già loggato.' if session[:user_id].present?
  end

end
