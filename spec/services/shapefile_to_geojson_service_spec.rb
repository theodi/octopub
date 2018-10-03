require 'rails_helper'

describe ShapefileToGeojsonService do

	describe '#convert' do

		describe 'converts a Shapefile to Geojson' do

			
		end
	end
	# context 'with a single .shp file' do
	#
	# 	let(:filename) { 'test-shapefile' }
	# 	let(:shp) { create(:dataset_file, filename: 'test.shp', title: 'test.shp') }
	# 	let(:shx) { create(:dataset_file, filename: 'test.shx', title: 'test.shx') }
	# 	let(:dbf) { create(:dataset_file, filename: 'test.dbf', title: 'test.dbf') }
	# 	let(:prj) { create(:dataset_file, filename: 'test.prj', title: 'test.prj') }
	# 	let(:dataset) { create(:dataset, dataset_files: [shp, shx, dbf, prj]) }
	# 	let(:file_list) { [shp, shx, dbf, prj] }
	# 	# Only check for JSON object, helpful to say that properties are present.
	# 	let(:geojson) {
	# 								{ "type": "FeatureCollection",
	# 									"features": [{
	# 										"type": "Feature",
	# 										"geometry": {
	# 											"type": "Point",
	# 											"coordinates": [-77.12911152370515, 38.79930767201779]
	# 										},
	# 										"properties": {
	# 											"name": "Van Dorn Street",
	# 											"marker-col": "#0000ff",
	# 											"marker-sym": "rail-metro",
	# 											"line": "blue"
	# 										},
	# 										"id": 0
	# 									}]
	# 								}
	# 							}
	#
	# 	before(:each) do
	# 		@conversion = ShapefileToGeojsonService.new(dataset, filename).perform
	# 	end
	#
	# 	pending 'can create a new geojson file' do
	# 		expect(dataset.dataset_file.count).to eq(5)
	# 	end
	#
	# 	pending 'can produce geojson' do
	# 		expect(@conversion).to eq(geojson)
	# 		expect(@conversion).to respond_with_content_type(:json)
	# 	end
	#
	# 	pending 'will fail with incorrect files' do
	#
	# 	end
	#
	# end
end