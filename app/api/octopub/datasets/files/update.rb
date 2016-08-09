module Octopub
  module Datasets
    module Files
      class Update < Grape::API

        before do
          authenticate!
          find_dataset
        end

        desc 'Updates a file in an existing dataset.',
             detail:'Returns a Job URL, which you can poll to check the creation status of a job',
             consumes: ['multipart/form-data'],
             http_codes: [
              { code: 202, message: 'OK', model: Octopub::Entities::Job }
             ],
             ignore_defaults: true
        params do
          requires :id, type: Integer, desc: 'The ID of the dataset'
          requires :file_id, type: Integer, desc: 'The ID of the file'
          requires :file, type: Hash do
            optional :description, type: String, desc: 'A short description of the file'
            optional :file, type: File, desc: 'The actual file'
          end
        end
        put 'datasets/:id/files/:file_id' do
          params.file = {
            id: params.file_id,
            description: params.file.description,
            file: params.file.file
          }

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
