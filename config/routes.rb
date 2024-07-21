Rails.application.routes.draw do
  root 'home#index'
  match 'auth/:provider/callback', to: 'sessions#create', via: [:get, :post]
  get 'auth/failure', to: redirect('/')
  get 'signout', to: 'sessions#destroy', as: 'signout'
  post 'upload', to: 'drive#upload'
end
