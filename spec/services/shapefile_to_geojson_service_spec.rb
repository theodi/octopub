require 'rails_helper'

describe ShapefileToGeojsonService do

	describe '#convert' do
		let(:filename) { 'test-shapefile' }
		let(:shp) { create(:dataset_file, filename: 'test.shp', title: 'test.shp', storage_key: 'abc1') }
		let(:shx) { create(:dataset_file, filename: 'test.shx', title: 'test.shx', storage_key: 'abc2') }
		let(:dbf) { create(:dataset_file, filename: 'test.dbf', title: 'test.dbf', storage_key: 'abc3') }
		let(:prj) { create(:dataset_file, filename: 'test.prj', title: 'test.prj', storage_key: 'abc4') }
		let(:geojson) {
										{ "type": "FeatureCollection",
											"features": [{
												"type": "Feature",
												"geometry": {
													"type": "Point",
													"coordinates": [-77.12911152370515, 38.79930767201779]
												},
												"properties": {
													"name": "Van Dorn Street",
													"marker-col": "#0000ff",
													"marker-sym": "rail-metro",
													"line": "blue"
												},
												"id": 0
											}]
										}
									}

		let(:dataset) { create(:dataset, name: filename, dataset_files: [shp, shx, dbf, prj]) }

		describe 'converts a Shapefile to Geojson' do

			file_storage_service = double("file_storage_service")
			allow(file_storage_service).to receive(:get_object).with('abc1').and_return()
			
			before(:each) do
				ShapefileToGeoJSON.new(dataset).convert
			end

			it 'creates an additional dataset_file' do
				expect(dataset.dataset_file.count).to eq(5)
			end

			pending 'will fail with incorrect files' do
			end
		end
	end
end