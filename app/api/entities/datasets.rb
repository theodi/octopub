module Octopub
  module Entities
    class Datasets < Grape::Entity
      expose :datasets, merge: true, using: Octopub::Entities::Dataset
    end
  end
end
