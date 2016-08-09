module Octopub
  module Datasets
    module Files
      class Create < Grape::API

        before do
          authenticate!
          find_dataset
        end

        desc 'Adds a file to an existing dataset.',
             detail: 'Returns a Job URL, which you can poll to check the creation status of a job',
             consumes: ['multipart/form-data'],
             ignore_defaults: true,
             http_codes: [
              { code: 202, message: 'OK', model: Octopub::Entities::Job }
             ]
        params do
          requires :id, type: Integer, desc: 'The ID of the dataset'
          requires :file, type: Hash do
            requires :title, type: String, desc: 'The name of the file'
            requires :description, type: String, desc: 'A short description of the file'
            requires :file, type: File, desc: 'The actual file'
          end
        end
        post 'datasets/:id/files' do
          params.files = [params.file]
          process_file(params.file)

          job = UpdateDataset.perform_async(@dataset.id, current_user.id, {}, params.file)

          status 202
          {
            job_url: api_jobs_path(id: job)
          }
        end

      end
    end
  end
end
