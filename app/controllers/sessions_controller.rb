class SessionsController < ApplicationController
  def create
    user = User.find_for_github_oauth(auth)

    if referer == "comma-chameleon"
      redirect_to redirect_url(api_key: user.api_key)
    else
      session[:user_id] = user.id
      User.delay.refresh_datasets(user.id)
      redirect_to root_url, :notice => "Signed in!"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => "Signed out!"
  end

  def redirect
    render nothing: true
  end

  private

    def auth
      request.env["omniauth.auth"]
    end

    def referer
      (request.env["omniauth.params"] || {})["referer"]
    end
end
