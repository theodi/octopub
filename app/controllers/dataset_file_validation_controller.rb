class DatasetFileValidationController < ApplicationController

	def index
		dataset_file_id = params[:dataset_file_id]
		@dataset_file = DatasetFile.find(dataset_file_id)
		@result = CsvlintValidateService.get_validated_csv(@dataset_file)
	end

end
