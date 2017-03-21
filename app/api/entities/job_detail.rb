module Octopub
  module Entities
    class JobDetail < Grape::Entity
      include GrapeRouteHelpers::NamedRouteMatcher

      expose :status, documentation: { type: "String", desc: "The status of the job", values: ["complete", "error", "running"]  }
      expose :errors, if: lambda { |job, _options| job.status == "error" }, documentation: { type: "String", desc: "If the job status is `error`, the errors that the job encountered", is_array: true }
      expose :dataset_url, if: lambda { |job, _options| job.status == "complete" },  documentation: { type: "String", desc: "If the job status is `complete`, the URL of the created / updated dataset" } do |job|
        api_datasets_path(id: job.dataset.id)
      end
    end
  end
end
