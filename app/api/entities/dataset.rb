module Octopub
  module Entities
    class Dataset < Grape::Entity
      include GrapeRouteHelpers::NamedRouteMatcher

      expose :id
      expose :url do |dataset|
        api_datasets_path(id: dataset.id)
      end

      expose :name
      expose :description
      expose :publisher do
        expose :publisher_name, as: :name
        expose :publisher_url, as: :url
      end
      expose :license do |dataset|
        license = Odlifier::License.define(dataset.license)
        {
          id: license.id,
          title: license.title,
          url: license.url
        }
      end
      expose :frequency
      expose :owner
      expose :url, as: :github_url
      expose :gh_pages_url
      expose :certificate_url
      expose :dataset_files, using: Octopub::Entities::File, as: :files
    end
  end
end
