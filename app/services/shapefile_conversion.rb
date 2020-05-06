require 'rgeo/shapefile'
require 'rgeo/geo_json'

class ShapefileConversion

	def initialize(file)
		@shp_file = file
	end

	def convert
		create_features_collection(@shp_file)
		convert_features_collection_to_geojson(@features_collection)
	end

	def create_features_collection(shp_file)
		features = []

		# Factory to set SRID (WGS84)- Is this being set correctly? Discuss
		factory = RGeo::Geographic.spherical_factory(:srid => 4326)

		# Open Shapefile with SRID factory
		RGeo::Shapefile::Reader.open(shp_file, :factory => factory) do |file|

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

	def convert_features_collection_to_geojson(features_collection)
		geojson = RGeo::GeoJSON.encode(features_collection)
		geojson.to_json
	end

	private

	def add_features_to_collection(features)
		RGeo::GeoJSON::FeatureCollection.new(features)
	end
end