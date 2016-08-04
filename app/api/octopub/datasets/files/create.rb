module Octopub
  module Datasets
    module Files
      class Create < Grape::API

        before do
          authenticate!
          find_dataset
        end

        desc 'Adds a file or files to an existing dataset', http_codes: [
          { code: 202, message: 'OK', model: Octopub::Entities::Job }
        ],
        ignore_defaults: true
        params do
          requires :id, type: Integer, desc: 'The ID of the dataset'
          requires :files, type: Array do
            requires :title, type: String, desc: 'The name of the file'
            requires :description, type: String, desc: 'A short description of the file'
            requires :file, type: File, desc: 'The actual file'
          end
        end
        post 'datasets/:id/files' do
          process_files(params.files) if params.files

          job = UpdateDataset.perform_async(@dataset.id, current_user.id, {}, params["files"])

          status 202
          {
            job_url: api_jobs_path(id: job)
          }
        end

      end
    end
  end
end
