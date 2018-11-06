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
		@model.model_schema_fields.build
		@user_id = current_user.id
	end

	def create
		@model = Model.create(create_params)
		create_model_constraints(@model)

		if @model.save
			redirect_to dataset_file_schemas_path
		else
			@user_id = current_user.id
			render :new
		end
	end

	private

	def create_params
		params.require(:model).permit(:name, :description, :user_id,
			model_schema_fields_attributes: [:name,
			model_schema_constraints: [:name, :type, :required, :unique, :min_length,
				:max_length, :minimum, :maximum, :pattern, :date_pattern
				]
			]
		)
	end

	# params.require(:model).permit(:name, :description, :user_id,
	# 	model_schema_fields_attributes: [:name,
	# 	model_schema_constraints: [:name, :type, :required, :unique, :min_length,
	# 		:max_length, :minimum, :maximum, :pattern, :date_pattern
	# 		]
	# 	]
	# )

	def create_model_constraints(model)
		model.model_schema_fields.map do |field|
			constraint = ModelSchemaConstraint.new()
			constraint.model_schema_field_id = field.id
			constraint.save
		end
	end

end