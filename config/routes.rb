MarketSentimentAnalysis::Application.routes.draw do

  #set applicaiton root route
  root 'financial_history_data#index'

  #routes for creating and destroying users
  post 'users' => 'users#create', :as => 'users'
  get 'delete' => "users#destroy", :as => "delete_user"

  #new password get route is for logged in user password reset
  get 'new_password' => 'users#send_password', :as => 'new_password'

  #send password post route is for users who cannot remember password
  post 'send_password' => 'users#send_password', :as => 'send_password'

  #routes to handle twilio user response for password reset and new user verification
  get 'verify_number' => 'users#verify_number', :as => 'verify_number'
  get 'reset_password' => 'users#reset_password', :as => 'reset_password'

  #routes for session handling
  get "log_out" => "sessions#destroy", :as => "log_out"
  resources :sessions

end
