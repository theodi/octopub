module Octopub
  module Datasets
    class Show < Grape::API

      desc 'Lists the name and Github pages URL for all datasets created by Octopub.'
      params do
        requires :id, type: Integer, desc: 'The ID of the dataset'
      end
      namespace :datasets do
        get ':id' do
          authenticate!
          find_dataset

          dataset_presenter(@dataset)
        end
      end
      
    end
  end
end
