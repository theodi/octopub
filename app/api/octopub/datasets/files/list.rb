module Octopub
  module Datasets
    module Files
      class List < Grape::API

        namespace :datasets do
          namespace ':id' do
            desc 'Lists all files for a dataset'
            params do
              requires :id, type: Integer, desc: 'The ID of the dataset'
            end
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
end
