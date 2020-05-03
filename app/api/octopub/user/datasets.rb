module Octopub
  module User
    class Datasets < Grape::API
      desc 'Lists all the datasets for the authenticated user.', is_array: true, http_codes: [
        { code: 200, message: 'OK', model: Octopub::Entities::Dataset }
      ]
      get '/user/datasets' do
        authenticate!

        datasets = current_user.all_datasets

        Octopub::Entities::Datasets.represent({datasets: datasets})
      end
    end
  end
end
