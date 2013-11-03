class SessionsController < ApplicationController
  
  def new
  end

  def create
    user = User.authenticate(session_params[:phone_number], session_params[:password])
    if user
      #removed remember me functionality 11/03/2013 for simplicity. No risk in creating a permanent cookie for this app.
      cookies.permanent[:auth_token] = user.auth_token
      redirect_to root_url, :notice => "Logged in!"
    else
      flash.now.alert = "Invalid phone number or password"
      redirect_to root_url, :notice => "Login failed. Try again."
    end
  end

  def destroy
    cookies.delete(:auth_token)
    redirect_to root_url, :notice => "Logged out!"
  end
  
  private
  
  def session_params
    params.permit(:phone_number, :password)
  end

end
