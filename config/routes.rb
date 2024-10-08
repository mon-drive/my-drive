Rails.application.routes.draw do

  #get 'admin/admin_page'
  get 'settings/show'
  get 'settings/update'
  root 'home#index'

  # Route for OmniAuth
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  get 'auth/failure', to: 'sessions#auth_failure'

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

  # Route for empty bin
  post 'drive/empty_bin', to: 'drive#empty_bin', as: 'empty_bin'

  resources :items, controller: 'drive', only: [] do
    member do
      patch 'rename'
      get 'share'
      get 'export'
      delete :delete_item
      get 'properties', defaults: { format: 'json' }
    end
  end

  # Route for rename item
  post 'share', to: 'drive#share'

  # Route for export item
  post 'export', to: 'drive#export'

  # Settings route
  get 'settings', to: 'drive#setting'

  # Route for extection
  get 'extension', to: 'drive#extension'

  # Route for export folder
  post 'export_folder', to: 'drive#export_folder'

  # Route for move item
  get 'move_item', to: 'drive#move_item'

  # Route for move folder
  delete 'delete_account', to: 'sessions#delete_account'

  # Route for upload folder
  post 'upload_folder/:folder_id', to: 'drive#folder_scan', as: 'upload_folder'

  # Route for changing locale
  post 'set_locale', to: 'application#change_locale'

  post '/update_name', to: 'drive#update_name'

  # Route for admin
  get '/admin', to: 'admin#admin_page', as: 'admin'
  patch 'admin/suspend_user/:id', to: 'admin#suspend_user', as: 'suspend_user_admin'


end
