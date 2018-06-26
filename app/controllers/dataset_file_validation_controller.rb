class DatasetFileValidationController < ApplicationController

	def index
		dataset_file_id = params[:dataset_file_id]
		dataset_file = DatasetFile.find(dataset_file_id)
		@results = CsvlintValidateService.validate_single_csv(dataset_file)
	end

end
