module Octopub
  class Jobs < Grape::API
    desc 'Checks the status of a dataset edit / create job.'
    namespace :jobs do
      get ':id' do
        @dataset = Dataset.find_by_job_id(params[:id])
        @error = Error.find_by_job_id(params[:id])
        if @dataset
          {
            status: "complete",
            dataset_url: api_datasets_path(id: @dataset.id)
          }
        elsif !@error.nil?
          {
            status: "error",
            errors: @error.messages
          }
        else
          {
            status: "running"
          }
        end
      end
    end
  end
end
