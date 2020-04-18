class ModelsController < ApplicationController

	before_action :set_licenses, only: [:create, :new, :edit, :update]

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
		@model.model_schema_fields.build
		@user_id = current_user.id
	end

	def create
		@model = Model.create(create_params)
		create_constraints(@model)

		if @model.save
			redirect_to dataset_file_schemas_path
		else
			@user_id = current_user.id
			render :new
		end
	end

	private

	def create_params
		params.require(:model).permit(:name, :description, :user_id, :owner, :license, model_schema_fields: [:name, :description, :type])
	end

	def constraint_params
		params.require(:model).permit!
	end

	def create_constraints(model)
		model.model_schema_fields.map do |field|
			constraints = constraint_params["model_schema_fields_attributes"]["0"]["model_schema_constraints"]
			ModelSchemaField.create({
				model_schema_field_id: 		field.id,
				required: 								constraints["required"],
				unique: 									constraints["unique"],
				min_length: 							constraints["min_length"],
				max_length: 							constraints["max_length"],
				minimum: 									constraints["minimum"],
				maximum: 									constraints["maximum"],
				pattern: 									constraints["pattern"],
				date_pattern: 						constraints["date_pattern"],
				type: 										constraints["type"]
			})
		end
	end

end