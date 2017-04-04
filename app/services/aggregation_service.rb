class AggregationService

  def initialize(output_schema)
    @output_schema = output_schema
    @dataset_file_schema = @output_schema.dataset_file_schema
    @group_by = @output_schema.grouping_schema_fields.first.name
    @total_by = @output_schema.totaling_schema_fields.pluck(:name)
  end

  def perform
    Rails.logger.info "in aggregation service, perform"
    datafiles = get_all_relevant_datafiles
    @aggregated_data = aggregate_datafiles
    produce_aggregated_dataset_and_files(@aggregated_data)
  end

  def get_all_relevant_datafiles
    @dataset_files = DatasetFile.where(dataset_file_schema: @dataset_file_schema).to_a
  end

  def aggregate_datafiles
    aggregated_data = Hash.new
    get_all_relevant_datafiles.each do |dataset_file|
      aggregated_data.deep_merge!(aggregate_file(dataset_file)) { |key, original_value, new_value| original_value + new_value }
    end
    aggregated_data
  end

  def aggregate_file(dataset_file)
    # Fetch from S3
    string_io_of_csv = FileStorageService.get_string_io(dataset_file.storage_key)

    results_hash = Hash.new

    # This may need refactoring to handle big files in memory
    # TODO revisit this, I'm sure it can be done in a neater fashion
    csv = CSV.parse(string_io_of_csv, headers: true)

    csv.each_with_object(Hash.new) do |(k,v), output_hash|
      current = output_hash[k[@group_by]]
      if current.nil?
        output_hash[k[@group_by]] = Hash.new
        @total_by.each do |total|
          output_hash[k[@group_by]][total] = 0
        end
      end
      @total_by.each do |total|
        output_hash[k[@group_by]][total] += k[total].to_i
      end
    end
  end

  def produce_aggregated_dataset_and_files(aggregated_data)
    # TODO
  end

end
