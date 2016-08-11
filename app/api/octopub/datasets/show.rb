module Octopub
  module Datasets
    class Show < Grape::API

      desc 'Shows a dataset by ID', http_codes: [
        { code: 200, message: 'OK', model: Octopub::Entities::Dataset }
      ]
      params do
        requires :id, type: Integer, desc: 'The ID of the dataset'
      end
      get 'datasets/:id' do
        authenticate!
        find_dataset

        Octopub::Entities::Dataset.represent(@dataset).as_json
      end

    end
  end
end
