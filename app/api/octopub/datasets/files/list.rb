module Octopub
  module Datasets
    module Files
      class List < Grape::API

        desc 'Lists all files for a dataset'
        params do
          requires :id, type: Integer, desc: 'The ID of the dataset'
        end
        get 'datasets/:id/files' do
          authenticate!
          find_dataset

          @dataset.dataset_files.map { |f| file_presenter(f) }
        end
        
      end
    end
  end
end
