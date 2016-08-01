module Octopub
  module Datasets
    class Files < Grape::API

      desc 'Lists all files for a dataset'
      params do
        requires :id, type: Integer, desc: 'The ID of the dataset'
      end
      namespace :datasets do
        namespace ':id' do
          get :files do
            authenticate!
            find_dataset

            @dataset.dataset_files.map { |f| file_presenter(f) }
          end
        end
      end

    end
  end
end
