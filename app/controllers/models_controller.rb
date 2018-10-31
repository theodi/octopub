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
		@user_id = current_user.id
	end

	def create
		logger.info "ModelController: In create"
		process_model
		@model = Model.new(create_params)
		# update_dataset_file_schema_with_json_schema(@model)
		# populate_schema_fields_and_constraints(@model)

		if @model.save
			redirect_to dataset_file_schemas_path
		else
			@user_id = current_user.id
			render :new
		end
	end

	private

	def create_params
    params.require(:model).permit(:name, :description, :user_id, :model_schema_fields, :url_in_s3, :storage_key)
  end

	def process_model
		model_reference = params["model"]
		return if model_reference.nil?

		storage_object = FileStorageService.create_and_upload_public_object(model_reference["name"], model_reference["model_schema_fields"].to_s)

		params["model"]["url_in_s3"] = storage_object.public_url
		params["model"]["storage_key"] = storage_object.key
	end

	# def update_dataset_file_schema_with_json_schema(model_schema)
	# 	Rails.logger.info ""
	# 	model_schema.update(schema: load_json_from_s3(model_schema.url_in_s3))
	# end
	#
	# def populate_schema_fields_and_constraints(model_schema)
  #   Rails.logger.info "in populate_schema_fields_and_constraints"
  #   if model_schema.schema_fields.empty? && model_schema.schema.present?
  #     Rails.logger.info "in populate_schema_fields_and_constraints - we have no fields and schema, so crack on"
  #     model_schema.json_table_schema['fields'].each do |field|
  #       Rails.logger.info "in populate_schema_fields_and_constraints #{field}"
  #       unless field['constraints'].nil?
  #         field['schema_constraint_attributes'] = field['constraints']
  #         field.delete('constraints')
  #       end
  #       model_schema.schema_fields.create(field)
  #     end
  #   end
  # end

end