class CsvlintValidateService

	require 'csvlint'

	def self.validate_csv(file)
		csv = get_s3_string(file)
		# schema = Csvlint::Schema.load_from_string(URI.escape(file.dataset_file_schema.url), file.dataset_file_schema.schema)
		# tempfile = Tempfile.new 'uploaded'
		# tempcsv = File.new(file.tempfile)

		# The schema object below is correct for passing to validator
		schema = file.dataset_file_schema.parsed_schema
		# file_validation = Csvlint::Validator.new(csv, {}, schema)

		validator = lint_csv(csv, schema)
		update_database_attributes(validator, file)
	end

	def self.get_validated_csv(file)
		csv_string = get_s3_string(file)
		schema = file.dataset_file_schema.parsed_schema
		lint_csv(csv_string, schema)
	end

	def self.lint_csv(csv, schema)
		return Csvlint::Validator.new(csv, {}, schema)
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
		schema = file.dataset_file_schema.parsed_schema
		csv = lint_csv(csv_string, schema)

		csv.warnings.count > 0 ? "warnings" : "valid"
	end

end
