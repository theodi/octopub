require 'grape-swagger'

require 'entities/file'
require 'entities/dataset'
require 'entities/datasets'
require 'entities/public_datasets'
require 'entities/job'

class API < Grape::API
  prefix 'api'
  version 'v1', using: :accept_version_header

  format :json

  helpers do
    include ActionController::HttpAuthentication::Token

    def current_user
      return nil if headers['Authorization'].nil?
      @current_user ||= User.find_by_api_key(token)
    end

    def token
      token_params_from(headers['Authorization']).shift[1]
    end

    def authenticate!
      error!('401 Unauthorized', 401) unless current_user
    end

    def find_dataset
      @dataset = ::Dataset.find(params.id.to_i)
      error!('404 Not Found', 404) if @dataset.nil?
      error!('403 Forbidden', 403) unless current_user.all_dataset_ids.include?(@dataset.id)
    end

    def process_files(files)
      files.each do |f|
        if f["file"]
          key ="uploads/#{SecureRandom.uuid}/#{f["file"].original_filename}"
          obj = S3_BUCKET.object(key)
          obj.put(body: f["file"].tempfile.read, acl: 'public-read')
          f["file"] = obj.public_url
        end
      end
    end
  end

  mount Octopub::Datasets::List
  mount Octopub::Datasets::Show
  mount Octopub::Datasets::Create
  mount Octopub::Datasets::Update

  mount Octopub::Datasets::Files::List
  mount Octopub::Datasets::Files::Create
  mount Octopub::Datasets::Files::Update

  mount Octopub::Jobs

  mount Octopub::User::Datasets

  add_swagger_documentation models: [
    Octopub::Entities::Dataset,
    Octopub::Entities::Datasets,
    Octopub::Entities::File,
    Octopub::Entities::Job
  ]
end
