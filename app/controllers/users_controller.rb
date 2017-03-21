class UsersController < ApplicationController

  before_action :check_signed_in?, only: [:edit, :update, :organizations]

  def index
    render_403_permissions unless admin_user
    @users = User.all
  end

  def show
    @user = User.find(params[:id])
  end

  def edit
  end

  def update
    current_user.update(user_params)
    redirect_to root_path, notice: "User details updated"
  end

  private

    def user_params
      params.require(:user).permit(:email, :twitter_handle)
    end

    def check_signed_in?
      render_403 if current_user.nil?
    end
end
