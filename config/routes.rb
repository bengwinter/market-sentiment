MarketSentimentAnalysis::Application.routes.draw do

  root 'financial_history_data#index'
  get "log_out" => "sessions#destroy", :as => "log_out"
  post 'users' => 'users#create', :as => 'users'
  patch 'update' => "users#update", :as => "user"
  get 'delete' => "users#destroy", :as => "delete_user"
  get 'new_password' => 'users#send_password', :as => 'new_password'
  post 'send_password' => 'users#send_password', :as => 'send_password'
  get 'verify_number' => 'users#verify_number', :as => 'verify_number'
  get 'reset_password' => 'users#reset_password', :as => 'reset_password'

  resources :sessions

end
