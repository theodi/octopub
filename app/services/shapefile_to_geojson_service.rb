class ShapefileToGeojsonService
	require 'rgeo/shapefile'
	require 'rgeo/geo_json'

	def initialize(files, filename)
		@shp = files
		@shp_name = filename
	end
end