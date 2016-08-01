module Octopub
  module Datasets
    class Create < Grape::API

      desc 'Creates a dataset for an authenticated user. Returns a Job URL, which you can then poll to check the creation status of a job'
      params do
        requires :dataset, type: Hash do
          requires :name, type: String, desc: 'The name of the dataset'
          optional :description, type: String, desc: 'A short description of the dataset'
          optional :owner, type: String, desc: 'The Github organisation to publish the dataset to'
          optional :publisher_name, type: String, desc: 'The name of the person / organisation publishing the data'
          optional :publisher_url, type: String, desc: 'The website of the person / organisation publishing the data'
          requires :license, type: String, desc: 'The ID of the dataset\'s license', values: ["cc-by", "cc-by-sa", "cc0", "OGL-UK-3.0", "odc-by", "odc-pddl"]
          optional :frequency, type: String, desc: 'How freqently the dataset is updated', values: ['One-off', 'Annual', 'Every working day', 'Daily', 'Monthly', 'Every minute', 'Every quarter', 'Half yearly', 'Weekly']
          optional :schema, type: String, desc: 'The URL of a JSON table schema to validate against your file(s)'
        end
        requires :files, type: Array do
          requires :title, type: String, desc: 'The name of the file'
          optional :description, type: String, desc: 'A short description of the file'
          requires :file, type: File, desc: 'The actual file'
        end
      end
      post :datasets do
        authenticate!
        process_files(params["files"])
        job = CreateDataset.perform_async(params["dataset"], params["files"], current_user.id)

        {
          job_url: api_jobs_path(id: job)
        }
      end

    end
  end
end
