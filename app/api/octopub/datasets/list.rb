module Octopub
  module Datasets
    class List < Grape::API
      desc 'Lists the name and Github pages URL for all datasets created by Octopub.', is_array: true, http_codes: [
        { code: 200, message: 'OK', model: Octopub::Entities::Dataset }
      ]
      get :datasets do
        datasets = ::Dataset.all.order(created_at: :desc)
        Octopub::Entities::Datasets.represent({datasets: datasets}, only: [{datasets: [:name, :gh_pages_url] }])
      end
    end
  end
end
