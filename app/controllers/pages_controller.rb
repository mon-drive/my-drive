class PagesController < ApplicationController
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
    # Logica per completare l'iscrizione, ad esempio:
    # - Aggiornare l'utente con il piano selezionato
    # - Inviare una conferma via email
    # - Eseguire altre azioni necessarie

    # Redirect alla homepage o a una pagina di conferma
    redirect_to root_path, notice: "Iscrizione completata con successo."
  end

end
