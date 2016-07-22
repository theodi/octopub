class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user

  layout ENV['LAYOUT'] || 'application'

  def index
    render "#{ENV['INDEX_TEMPLATE'] || 'index'}.html.erb"
  end

  def api
  end

  private

    def current_user
      @current_user ||= begin
        if session[:user_id]
          User.find(session[:user_id])
        elsif params[:api_key]
          User.find_by_api_key params[:api_key]
        end
      end
    end

    def render_404
      render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found
    end

    def render_403
      render '403', :status => :forbidden
    end
end
