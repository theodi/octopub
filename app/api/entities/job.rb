module Octopub
  module Entities
    class Job < Grape::Entity
      include GrapeRouteHelpers::NamedRouteMatcher

      expose :job_url do |job|
        api_jobs_path(id: job)
      end
    end
  end
end
