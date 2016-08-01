module Octopub
  module Datasets
    class Update < Grape::API

      before do
        authenticate!
        find_dataset
      end

      desc 'Edits a dataset for an authenticated user. Returns a Job URL, which you can then poll to check the creation status of a job'
      params do
        requires :id, type: Integer, desc: 'The ID of the dataset'
        optional :dataset, type: Hash do
          optional :description, type: String, desc: 'A short description of the dataset'
          optional :publisher_name, type: String, desc: 'The name of the person / organisation publishing the data'
          optional :publisher_url, type: String, desc: 'The website of the person / organisation publishing the data'
          optional :license, type: String, desc: 'The ID of the dataset\'s license', values: ["cc-by", "cc-by-sa", "cc0", "OGL-UK-3.0", "odc-by", "odc-pddl"]
          optional :frequency, type: String, desc: 'How freqently the dataset is updated', values: ['One-off', 'Annual', 'Every working day', 'Daily', 'Monthly', 'Every minute', 'Every quarter', 'Half yearly', 'Weekly']
        end
      end
      put 'datasets/:id' do
        job = UpdateDataset.perform_async(@dataset.id, current_user.id, (params.dataset || {}), {})

        status 202
        {
          job_url: api_jobs_path(id: job)
        }
      end

    end
  end
end
