class SessionsController < ApplicationController
  def create
    user = User.find_for_github_oauth(auth)

    if format == "json"
      render json: {
        api_key: user.api_key
      }.to_json
    else
      session[:user_id] = user.id
      redirect_to root_url, :notice => "Signed in!"
    end
  end

  def destroy
    session[:user_id] = nil
    redirect_to root_url, :notice => "Signed out!"
  end

  private

    def auth
      request.env["omniauth.auth"]
    end

    def format
      (request.env["omniauth.params"] || {})["format"]
    end
end
