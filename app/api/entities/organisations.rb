module Octopub
  module Entities
    class Organisations < Grape::Entity
      include GrapeRouteHelpers::NamedRouteMatcher
      expose :login do |org|
        org.organization.login
      end
    end
  end
end
