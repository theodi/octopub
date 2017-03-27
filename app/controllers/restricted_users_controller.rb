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
    allocate_schemas
    @user.update(user_params)
    redirect_to users_path, notice: "User details updated"
  end

  private

  def allocate_schemas
    if params[:user].key?(:schema_category_ids)
      schema_category_ids = params[:user][:schema_category_ids]

      schema_categories = SchemaCategory.find(schema_category_ids)
      dataset_file_schema_ids = schema_categories.map { |sc| sc.dataset_file_schemas.pluck(:id) }.flatten.uniq

      current_allocated_schemas = params[:user][:allocated_dataset_file_schema_ids] ||= []

      params[:user][:allocated_dataset_file_schema_ids] = current_allocated_schemas + dataset_file_schema_ids
      params[:user].delete(:schema_category_ids)
    end

  end

  def user_params
    params.require(:user).permit(:email, :twitter_handle, :role, :restricted, allocated_dataset_file_schema_ids: [], schema_category_ids: [])
  end
end
