class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user

  def index
  end


  private

    def current_user
      @current_user ||= begin
        if session[:user_id]
          User.find(session[:user_id])
        elsif params[:token]
          User.find_by_token params[:token]
        end
      end
    end

    def render_404
      render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found
    end
end
