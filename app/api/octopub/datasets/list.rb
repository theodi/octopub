module Octopub
  module Datasets
    class List < Grape::API
      desc 'Lists the name and Github pages URL for all datasets created by Octopub.'
      get :datasets do
        {
          datasets: ::Dataset.all.order(created_at: :desc).map { |d|
            {
              name: d.name,
              github_url: d.github_url
            }
          }
        }
      end
    end
  end
end
