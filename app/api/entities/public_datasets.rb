module Octopub
  module Entities
    class PublicDatasets < Grape::Entity
      expose :name
      expose :gh_pages_url
    end
  end
end
