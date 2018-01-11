class SessionsController < ApplicationController
  
  # Create a new user session.
  def create
    # Omniauth-github returns a hash of information after authenticating the user. Find or create
    # the user and return them.
    user = User.find_for_github_oauth(auth)

    if referer == "comma-chameleon"
      redirect_to redirect_url(api_key: user.api_key)
    else
      # Store user id in the session cookie.
      # TODO Move to a session helper file.
      session[:user_id] = user.id
      # Asynchronously refresh the datasets (using Sidekiq delayed extensions).
      User.delay.refresh_datasets(user.id)
      redirect_to root_url, :notice => "Signed in!"
    end
  end

  # Destroy the current session if one exists.
  def destroy
    # TODO Move to a session helper file.
    session[:user_id] = nil
    redirect_to root_url, :notice => "Signed out!"
  end

  def redirect
    head :ok
  end

  private

    def auth
      request.env["omniauth.auth"]
    end

    # Get the request referer.
    def referer
      # Request.env is a Rails object that contains information on your visitor’s environment (e.g. 
      # browser, referrer) and information on your server’s environment.
      (request.env["omniauth.params"] || {})["referer"]
    end
end
