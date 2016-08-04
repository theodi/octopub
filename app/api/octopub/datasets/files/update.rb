module Octopub
  module Datasets
    module Files
      class Update < Grape::API

        before do
          authenticate!
          find_dataset
        end

        desc 'Updates a file or files in an existing dataset', http_codes: [
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
          params.files = [
            {
              id: params.file_id,
              description: params.file.description,
              file: params.file.file
            }
          ]

          process_files(params.files)

          job = UpdateDataset.perform_async(@dataset.id, current_user.id, {}, params.files)

          status 202
          {
            job_url: api_jobs_path(id: job)
          }
        end

      end
    end
  end
end
