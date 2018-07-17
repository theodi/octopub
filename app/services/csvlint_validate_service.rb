class CsvlintValidateService

	require 'csvlint'

	def self.validate_csv(file)
		csv = get_s3_string(file)
		validator = validator(csv, file)
		update_database_attributes(validator, file)
	end

	def self.validator(csv, file)
		if file.dataset_file_schema
			schema = file.dataset_file_schema.parsed_schema
			return Csvlint::Validator.new(csv, {}, schema)
		else
			return Csvlint::Validator.new(csv)
		end
	end

	def self.get_s3_string(file)
		return FileStorageService.get_string_io(file.storage_key)
	end

	def self.get_validated_csv(file)
		csv = get_s3_string(file)
		validator(csv, file)
	end

	def self.generate_badge(file)
		!file.validation ? "invalid" : generate_badge_valid_file(file)
	end

	private

	def self.update_database_attributes(csv, file)
		csv.valid? ? file.update(validation: true) : file.update(validation: false)
	end

	def self.generate_badge_valid_file(file)
		csv = get_s3_string(file)
		validated_csv = validator(csv, file)
		validated_csv.warnings.count > 0 ? "warnings" : "valid"
	end

end
