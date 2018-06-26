class CsvlintValidateService

	require 'csvlint'

	def self.validate_csv(dataset)
		Rails.logger.info "Dataset file validation - CSV"
		dataset_files = dataset.dataset_files

		dataset_files.each do |file|
			s3_string = FileStorageService.get_string_io(file.storage_key)
			validator = Csvlint::Validator.new(s3_string)

			if validator.valid?
				file.update(validation: true)
			else
				file.update(validation: false)
			end
		end
	end

end
