class CsvlintValidateService

	require 'csvlint'

	def self.validate_dataset_collection(dataset)
		dataset_files = dataset.dataset_files

		dataset_files.each do |file|
			csv = get_s3_string(file)
			update_database_attributes(csv, file)
		end
	end

	def self.validate_single_csv(file)
		csv = get_s3_string(file)
	end

	def self.generate_badge(file)
		file.validation ? "valid" : CsvlintValidateService.generate_badge_invalid_file(file)
	end

	private

	def self.get_s3_string(file)
		s3_string = FileStorageService.get_string_io(file.storage_key)
		validator = Csvlint::Validator.new(s3_string)
	end

	def self.update_database_attributes(csv, file)
		if csv.valid?
			file.update(validation: true)
		else
			file.update(validation: false)
		end
	end

	def self.generate_badge_invalid_file(file)
		csv = get_s3_string(file)
		csv.errors ? 'invalid' : 'warnings'
	end

end
