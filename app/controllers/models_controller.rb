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
		# PROCESS FILE HERE
		logger.info "ModelController: In create"
		@model = Model.new(create_params)
		update_dataset_file_schema_with_json_schema(@model)
		populate_schema_fields_and_constraints(@model)

		if @model.save
			redirect_to dataset_file_schemas_path
		end
	end

	private

	def create_params
    params.require(:model).permit(:name, :description, :user_id)
  end

	def update_dataset_file_schema_with_json_schema(model_schema)
		Rails.logger.info ""
		model_schema.update(schema: load_json_from_s3(dataset_file_schema.url_in_s3))
	end

	def populate_schema_fields_and_constraints(model_schema)
    Rails.logger.info "in populate_schema_fields_and_constraints"
    if model_schema.schema_fields.empty? && model_schema.schema.present?
      Rails.logger.info "in populate_schema_fields_and_constraints - we have no fields and schema, so crack on"
      model_schema.json_table_schema['fields'].each do |field|
        Rails.logger.info "in populate_schema_fields_and_constraints #{field}"
        unless field['constraints'].nil?
          field['schema_constraint_attributes'] = field['constraints']
          field.delete('constraints')
        end
        model_schema.schema_fields.create(field)
      end
    end
  end

end