module Octopub
  class Dashboard < Grape::API
    desc 'Lists the name and Github pages URL for all datasets created by Octopub.'
    get :dashboard do
      authenticate!

      datasets = current_user.all_datasets

      {
        datasets: datasets.map { |d| dataset_presenter(d) }
      }
    end
  end
end
