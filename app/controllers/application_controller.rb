class ApplicationController < ActionController::Base
  # Prevent CSRF attacks by raising an exception.
  # For APIs, you may want to use :null_session instead.
  protect_from_forgery with: :exception
  helper_method :current_user, :admin_user

  include ActionController::HttpAuthentication::Token::ControllerMethods

  layout ENV['LAYOUT'] || 'application'

  def index
    @datasets = current_user.datasets if !current_user.nil?
    @dataset_file_schemas = DatasetFileSchema.where(user: current_user).order(created_at: :desc) if !current_user.nil?
    render "#{ENV['INDEX_TEMPLATE'] || 'index'}.html.erb"
  end

  def api
  end

  def getting_started
    @extra_class = 'getting-started'
  end

  def licenses
    set_licenses

    render json: {
      licenses: @licenses.map do |l|
        {
          id: l[1],
          name: l[0]
        }
      end
    }.to_json
  end

  def check_signed_in?
    render_403 if current_user.nil?
  end

  rescue_from CanCan::AccessDenied do |exception|
    Rails.logger.debug "Access denied on #{exception.action} #{exception.subject.inspect}"
    render_403
  end

  private

  def current_user
    @current_user ||= begin
      if session[:user_id]
        User.find(session[:user_id])
      elsif request.headers['HTTP_AUTHORIZATION']
        authenticate_or_request_with_http_token do |token, _options|
          User.find_by_api_key token
        end
      end
    end
  end

  def admin_user
    current_user if current_user.present? && current_user.admin?
  end

  def render_404
    render :file => "#{Rails.root}/public/404", :layout => false, :status => :not_found
  end

  def render_403
    render '403', :status => :forbidden
  end

  def render_403_permissions
    render '403_permissions', status: :forbidden
  end

  def set_licenses
    license_group = nil
    @licenses = {}
    
    Octopub::LICENCE_GROUPS.each_with_index do |g, i|
      if g != license_group
        @licenses[g] = []
      end
      odlifier_license = Odlifier::License.define(Octopub::WEB_LICENCES[i])
      @licenses[g] << { :id => odlifier_license.id, :name => Octopub::BIG_LICENCES[i] }
      license_group = g
    end
  end
end
