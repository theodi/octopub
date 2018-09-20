class ShapefileToGeojsonService
	require 'rgeo/shapefile'
	require 'rgeo/geo_json'

	def initialize(dataset)
		@dataset = dataset
		@shp_name = dataset.name
		@shp_files = dataset.dataset_files
	end

	def perform
		Rails.logger.info "ShapefileToGeoJSON: In perform"

		get_shapefiles(@shp_files, @shp_name)
		create_features_collection
		convert_features_collection_to_geojson
		save_geojson(@shp_name)
	end

	private

	def get_shapefiles(shp_files, shp_name)
		shp_files.each do |file|
			object = FileStorageService.get_object(file.storage_key)
			object.get(response_target: './tmp/shapefiles/' + shp_name + file_ext(file.filename))
		end
	end

	def create_features_collection
		features = []

		# Factory to set SRID (WGS84)- Is this being set correctly? Discuss
		factory = RGeo::Geographic.spherical_factory(:srid => 4326)

		# Open Shapefile with SRID factory
		RGeo::Shapefile::Reader.open(get_shp_file(@shp_name), :factory => factory) do |file|

			file.each do |record|

				# Factory to create a RGeo 'feature' for each record
				factory = RGeo::GeoJSON::EntityFactory.instance

				# Feature object for each Shapefile record
				feature = factory.feature(
					record.geometry,
					record.index,
					record.attributes
				)

				features << feature
			end
		end

		@features_collection = add_features_to_collection(features)
	end

	def convert_features_collection_to_geojson
		geojson = RGeo::GeoJSON.encode(@features_collection).to_json

		File.open("tmp/shapefiles/tmp.geojson", "w") do |f|
			f.write(geojson)
		end
	end

	def save_geojson(shp_name)
		geojson_data = File.read("tmp/shapefiles/tmp.geojson")
		object = FileStorageService.create_and_upload_public_object(shp_name + '.geojson', geojson_data)
		storage_key = FileStorageService.get_storage_key_from_public_url(object.public_url)

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

	def file_ext(file)
		File.extname(file)
	end

	def get_shp_file(shp_name)
		shp_file = shp_name + '.shp'
		Rails.root.join("tmp/shapefiles/#{shp_file}")
	end

	def add_features_to_collection(features)
		RGeo::GeoJSON::FeatureCollection.new(features)
	end

	def delete_temporary_files
		`rm -fr tmp/shapefiles/*`
	end
end