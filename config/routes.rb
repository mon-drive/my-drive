Rails.application.routes.draw do

  root 'home#index'

  # Route for OmniAuth
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  get 'auth/failure', to: redirect('/')

  # Route for logout
  get 'signout', to: 'sessions#destroy', as: 'signout'

  # Route for uploading file
  post 'upload', to: 'drive#upload'

  # Route for pricing page
  get 'pricing', to: 'pages#pricing'

  # Route for payment page
  get 'payment', to: 'pages#payment', as: 'payment'

  # Route for payment complete
  post 'payment_complete', to: 'pages#payment_complete', as: 'payment_complete'

  # Dashboard route
  get 'dashboard', to: 'drive#dashboard', as: 'dashboard'

end
