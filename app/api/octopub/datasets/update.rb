module Octopub
  module Datasets
    class Update < Grape::API

      before do
        authenticate!
        find_dataset
      end

      namespace :datasets do
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
        put ':id' do
          job = UpdateDataset.perform_async(@dataset.id, current_user.id, (params.dataset || {}), {})

          status 202
          {
            job_url: api_jobs_path(id: job)
          }
        end

        namespace ':id' do
          desc 'Adds a file or files to an existing dataset'
          params do
            requires :id, type: Integer, desc: 'The ID of the dataset'
            requires :files, type: Array do
              requires :title, type: String, desc: 'The name of the file'
              requires :description, type: String, desc: 'A short description of the file'
              requires :file, type: File, desc: 'The actual file'
            end
          end
          post :files do
            process_files(params.files) if params.files

            job = UpdateDataset.perform_async(@dataset.id, current_user.id, {}, params["files"])

            status 202
            {
              job_url: api_jobs_path(id: job)
            }
          end

          namespace :files do
            desc 'Updates a file or files in an existing dataset'
            params do
              requires :id, type: Integer, desc: 'The ID of the dataset'
              requires :file_id, type: Integer, desc: 'The ID of the file'
              requires :file, type: Hash do
                optional :description, type: String, desc: 'A short description of the file'
                optional :file, type: File, desc: 'The actual file'
              end
            end
            put ':file_id' do
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
  end
end
