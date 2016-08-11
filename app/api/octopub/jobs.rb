module Octopub
  class Jobs < Grape::API
    desc 'Checks the status of a dataset edit / create job.', http_codes: [
      { code: 200, message: 'OK', model: Octopub::Entities::JobDetail }
    ]
    namespace :jobs do
      get ':id' do
        @dataset = Dataset.find_by_job_id(params[:id])
        @error = Error.find_by_job_id(params[:id])
        if @dataset
          job = OpenStruct.new(status: "complete", dataset: @dataset)
        elsif !@error.nil?
          job = OpenStruct.new(status: "error", errors: @error.messages)
        else
          job = OpenStruct.new(status: "running")
        end
        Octopub::Entities::JobDetail.represent(job)
      end
    end
  end
end
