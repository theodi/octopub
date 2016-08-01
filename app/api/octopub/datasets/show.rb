module Octopub
  module Datasets
    class Show < Grape::API

      desc 'Shows a dataset by ID'
      params do
        requires :id, type: Integer, desc: 'The ID of the dataset'
      end
      get 'datasets/:id' do
        authenticate!
        find_dataset

        dataset_presenter(@dataset)
      end

    end
  end
end
