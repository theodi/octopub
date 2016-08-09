require 'grape-swagger'

require 'entities/file'
require 'entities/dataset'
require 'entities/datasets'
require 'entities/public_datasets'
require 'entities/job'
require 'entities/job_detail'
require 'entities/organisations'

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

    def process_file(file)
      if file["file"]
        key ="uploads/#{SecureRandom.uuid}/#{file["file"].original_filename}"
        obj = S3_BUCKET.object(key)
        obj.put(body: file["file"].tempfile.read, acl: 'public-read')
        file["file"] = obj.public_url
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
  mount Octopub::User::Organisations

  add_swagger_documentation models: [
    Octopub::Entities::Dataset,
    Octopub::Entities::Datasets,
    Octopub::Entities::File,
    Octopub::Entities::Job
  ],
  info: {
    title: 'Octopub API',
    description: """
# Octopub API

Octopub has a fully-featured API that allows you to view, create and update datasets.

Most endpoints require authentication. Logged in users can get their API key from their [account page](https://octopub.io/me).

Once you have your API key, you can authenticate with the API by adding an `Authorization` header to your API call.

## Endpoints

You can see the endpoints available below. To test endpoints that require authentication, enter your API key below.
    """,
    markdown: GrapeSwagger::Markdown::RedcarpetAdapter.new(render_options: { highlighter: :rouge })
  }
end
