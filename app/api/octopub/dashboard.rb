module Octopub
  class Dashboard < Grape::API
    desc 'Lists the name and Github pages URL for all datasets created by Octopub.', is_array: true, http_codes: [
      { code: 200, message: 'OK', model: Octopub::Entities::PublicDatasets }
    ]
    get :dashboard do
      authenticate!

      datasets = current_user.all_datasets

      Octopub::Entities::Datasets.represent({datasets: datasets})
    end
  end
end
