class ShapefileToGeojsonService

	def initialize(dataset)
		@dataset = dataset
		@shp_name = dataset.name
		@shp_files = dataset.dataset_files
	end

	def convert
		Rails.logger.info "ShapefileToGeoJSON: In perform"

		get_shapefiles(@shp_files, @shp_name)
		geojson = ShapefileConversion.new(get_shp_file(@shp_name)).convert
		create_geojson_dataset_file(@shp_name, geojson)
	end

	private

	def get_shapefiles(shp_files, shp_name)
		shp_files.each do |file|
			object = FileStorageService.get_object(file.storage_key)
			filename = "#{Rails.root}/tmp/#{shp_name}#{file_ext(file.filename)}"
			object.get(response_target: filename)
		end
	end

	def create_geojson_dataset_file(shp_name, geojson)
		shp_name = shp_name.parameterize

		object = FileStorageService.create_and_upload_public_object(shp_name + '.geojson', geojson)
		storage_key = FileStorageService.get_storage_key_from_public_url(object.public_url)

		create_dataset_file(shp_name, storage_key, object)
	end

	private

	def create_dataset_file(shp_name, storage_key, object)
		dataset_file_creation_hash = {
			"title"=>shp_name,
			"description"=>shp_name,
			"file"=>object.public_url,
			"dataset_file_schema_id"=>"",
			"storage_key"=>storage_key
		}

		delete_temporary_files

		DatasetFile.create(dataset_file_creation_hash)
	end

	def get_shp_file(shp_name)
		shp_file = shp_name + '.shp'
		Rails.root.join("#{Rails.root}/tmp/#{shp_file}")
	end

	def file_ext(file)
		File.extname(file)
	end

	def delete_temporary_files
		`rm -fr #{Rails.root}/tmp/*`
	end
end