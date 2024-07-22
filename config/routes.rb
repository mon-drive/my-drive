Rails.application.routes.draw do

  root 'home#index'

  # Rotte per OmniAuth
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  get 'auth/failure', to: redirect('/')

  # Rotta per logout
  get 'signout', to: 'sessions#destroy', as: 'signout'

  # Rotta per caricare file e visualizzare la pagina di pricing
  post 'upload', to: 'drive#upload'
  get 'pricing', to: 'pages#pricing'

  # Rotta per la pagina di pagamento
  get 'payment', to: 'pages#payment', as: 'payment'

  # Rotta per completare il pagamento
  post 'payment_complete', to: 'pages#payment_complete', as: 'payment_complete'

  # Rotta per processare il pagamento
  post 'process_payment', to: 'pages#process_payment'
  
end
