module Octopub
  module Datasets
    class Update < Grape::API

      before do
        authenticate!
        find_dataset
      end

      desc 'Edits a dataset for an authenticated user.',
           http_codes: [
             { code: 202, message: 'OK', model: Octopub::Entities::Job }
           ],
           consumes: ['multipart/form-data'],
           ignore_defaults: true,
           detail: 'Returns a Job URL, which you can poll to check the creation status of a job'
      params do
        requires :id, type: Integer, desc: 'The ID of the dataset'
        optional :dataset, type: Hash do
          optional :description, type: String, desc: 'A short description of the dataset'
          optional :publisher_name, type: String, desc: 'The name of the person / organisation publishing the data'
          optional :publisher_url, type: String, desc: 'The website of the person / organisation publishing the data'
          optional :license, type: String, desc: 'The ID of the dataset\'s license', values: Octopub::API_LICENCES
          optional :frequency, type: String, desc: 'How freqently the dataset is updated', values: Octopub::PUBLICATION_FREQUENCIES
        end
      end
      put 'datasets/:id' do
        job = UpdateDataset.perform_async(@dataset.id, (params.dataset || {}), [])

        status 202
        {
          job_url: api_jobs_path(id: job)
        }
      end

    end
  end
end
