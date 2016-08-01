module Octopub
  module Entities
    class File < Grape::Entity
      expose :id
      expose :title
      expose :description
      expose :filename
      expose :github_url
    end
  end
end
