class RestrictedUsersController < ApplicationController

  before_action :check_signed_in?, only: [:edit, :update]

  def edit
    render_403_permissions unless admin_user
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    redirect_to users_path, notice: "User details updated"
  end

  private

  def user_params
    params.require(:user).permit(:email, :twitter_handle)
  end

  def check_signed_in?
    render_403 if current_user.nil?
  end
end
