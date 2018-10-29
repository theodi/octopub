class ModelsController < ApplicationController

	def index
		redirect_to :controller => 'dataset_file_schemas', :action => 'index'
	end

	def show
		model_id = params[:id]
		@model = Model.find(model_id)
		render_403_permissions unless current_user == @model.user || admin_user
	end

	def new
		@model = Model.new
	end

	def create
		logger.info "ModelController: In create"
		@model = Model.new (create_params)
		@model.user_id = current_user.id
		
		if @model.save
			redirect_to dataset_file_schemas_path
		end
	end

	private

	def create_params
    params.require(:model).permit(:name, :description, :user_id)
  end
end