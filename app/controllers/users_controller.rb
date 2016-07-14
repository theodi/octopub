class UsersController < ApplicationController

  before_filter :check_signed_in?, only: [:edit, :update, :organizations]

  def new
  end

  def edit
  end

  def update
    current_user.update(user_params)
    redirect_to root_path, notice: "User details updated"
  end

  def organizations
    render json: {
      organizations: current_user.organizations
    }.to_json
  end

  private

    def user_params
      params.require(:user).permit(:email)
    end

    def check_signed_in?
      render_403 if current_user.nil?
    end
end
