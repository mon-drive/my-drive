Rails.application.routes.draw do

  get 'settings/show'
  get 'settings/update'
  root 'home#index'

  # Route for OmniAuth
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  get 'auth/failure', to: redirect('/')

  # Route for logout
  get 'signout', to: 'sessions#destroy', as: 'signout'

  # Route for uploading file
  post 'upload', to: 'drive#scan'

  # Route for creating new folder
  post 'new_folder', to: 'drive#create_folder'

  # Route for pricing page
  get 'pricing', to: 'pages#pricing'

  # Route for payment page
  get 'payment', to: 'pages#payment', as: 'payment'

  # Route for payment complete
  post 'payment_complete', to: 'pages#payment_complete', as: 'payment_complete'

  # Dashboard route
  get 'dashboard', to: 'drive#dashboard', as: 'dashboard'

  # Route for delete item
  delete 'delete_item', to: 'drive#delete_item'

  # Route for rename item
  post 'share', to: 'drive#share'

  # Settings route
  get 'settings', to: 'drive#setting'

end
