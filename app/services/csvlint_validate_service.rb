class CsvlintValidateService

	require 'csvlint'

	def self.validate_csv(dataset_files)
		dataset_files.each do |file|
			@s3_string = FileStorageService.get_string_io(file.storage_key)
			validator = Csvlint::Validator.new(@s3_string)
			validator.valid?
		end
	end

end
