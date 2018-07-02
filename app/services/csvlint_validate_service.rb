class CsvlintValidateService

	require 'csvlint'

	def self.validate_csv(file)
		csv_string = get_s3_string(file)
		validator = lint_csv(csv_string)
		update_database_attributes(validator, file)
	end

	def self.get_validated_csv(file)
		csv_string = get_s3_string(file)
		lint_csv(csv_string)
	end

	def self.lint_csv(csv_string)
		return Csvlint::Validator.new(csv_string)
	end

	def self.generate_badge(file)
		!file.validation ? "invalid" : generate_badge_valid_file(file)
	end

	private

	def self.get_s3_string(file)
		return FileStorageService.get_string_io(file.storage_key)
	end

	def self.update_database_attributes(csv, file)
		csv.valid? ? file.update(validation: true) : file.update(validation: false)
	end

	def self.generate_badge_valid_file(file)
		csv_string = get_s3_string(file)
		csv = lint_csv(csv_string)

		csv.warnings.count > 0 ? "warnings" : "valid"
	end

end
