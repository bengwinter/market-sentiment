class SessionsController < ApplicationController
  def new

  end

  def create
    user = User.authenticate(session_params[:phone_number], session_params[:password])

    if user
      session[:user_id] = user.id
      redirect_to root_url, :notice => "Logged in!"
    else
      flash.now.alert = "Invalid phone number or password"
      render "new"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => "Logged out!"
  end
  
  private

  def session_params
    params.permit(:phone_number, :password)
  end
end
