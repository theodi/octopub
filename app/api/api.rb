require 'grape-swagger'

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

    def dataset_presenter(dataset)
      license = Odlifier::License.define(dataset.license)
      {
        id: dataset.id,
        url: api_datasets_path(id: dataset.id),
        name: dataset.name,
        description: dataset.description,
        publisher: {
          name: dataset.publisher_name,
          url: dataset.publisher_url
        },
        license: {
          id: license.id,
          title: license.title,
          url: license.url
        },
        frequency: dataset.frequency,
        owner: dataset.owner,
        github_url: dataset.url,
        gh_pages_url: dataset.gh_pages_url,
        certificate_url: dataset.certificate_url,
        files: dataset.dataset_files.map { |f| file_presenter(f) }
      }
    end

    def file_presenter(file)
      {
        id: file.id,
        title: file.title,
        description: file.description,
        filename: file.filename,
        github_url: file.github_url
      }
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

  mount Octopub::Dashboard
  mount Octopub::Jobs

  add_swagger_documentation
end
