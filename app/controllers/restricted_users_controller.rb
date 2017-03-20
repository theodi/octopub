class RestrictedUsersController < ApplicationController
  before_action :check_signed_in?

  def edit
    render_403_permissions unless admin_user
    # TODO this should be the ones which the user *should* have access to
    @dataset_file_schemas = DatasetFileSchema.all
    @user = User.find(params[:id])
  end

  def update
    @user = User.find(params[:id])
    @user.update(user_params)
    redirect_to users_path, notice: "User details updated"
  end

  private

  def user_params
    params.require(:user).permit(:email, :twitter_handle, :role, :restricted, allocated_dataset_file_schema_ids: [] )
  end
end
