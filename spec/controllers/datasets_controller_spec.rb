
require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
    Dataset.skip_callback(:create, :after, :create_in_github)

    allow_any_instance_of(DatasetFile).to receive(:add_to_github) { nil }
    allow_any_instance_of(Dataset).to receive(:create_files) { nil }
  end

  after(:each) do
    Dataset.set_callback(:create, :after, :create_in_github)
  end

  describe 'index' do
    it "returns http success" do
      get 'index'
      expect(response).to be_success
    end

    it "gets the right number of datasets" do
      5.times { |i| create(:dataset, name: "Dataset #{i}") }
      get 'index'
      expect(assigns(:datasets).count).to eq(5)
    end
  end

  describe 'dashboard' do
    it "gets the right number of datasets" do
      request.env["omniauth.auth"] = OmniAuth.config.mock_auth[:github]

      5.times { |i| create(:dataset, name: "Dataset #{i}") }

      create(:dataset, user: @user)
      sign_in @user

      get 'dashboard'

      expect(assigns(:datasets).count).to eq(1)
    end

    it "refreshes datasets" do
      # This dataset exists
      dataset1 = create(:dataset, user: @user, repo: "dataset-1")
      allow_any_instance_of(Octokit::Client).to receive(:repository).with(dataset1.full_name)

      # This dataset has gone away
      dataset2 = create(:dataset, user: @user, repo: "dataset-2")
      allow_any_instance_of(Octokit::Client).to receive(:repository).with(dataset2.full_name) { raise Octokit::NotFound }

      sign_in @user

      get 'dashboard', refresh: true

      expect(assigns(:datasets).count).to eq(1)
      expect(assigns(:datasets).first).to eq(dataset1)
    end

    it 'gets a JSON dashboard' do
      5.times { |i| create(:dataset, name: "Dataset #{i}") }

      dataset = create(:dataset, user: @user)
      get 'dashboard', format: :json, api_key: @user.api_key

      json = JSON.parse(response.body)

      expect(json['datasets'].count).to eq(1)
      expect(json['datasets'].first['name']).to eq(dataset.name)
    end
  end

  describe 'new dataset' do
    it 'initializes a new dataset' do
      sign_in @user

      get 'new'
      expect(assigns(:dataset).class).to eq(Dataset)
    end
  end

  describe 'create dataset' do
    before do
      sign_in @user

      @name = "My cool dataset"
      @description = "This is a description"
      @publisher_name = "Cool inc"
      @publisher_url = "http://example.com"
      @license = "OGL-UK-3.0"
      @frequency = "Monthly"
      @files ||= []
    end

    it 'returns an error if there are no files specified' do
      sign_in @user

      request = post 'create', dataset: {
        name: @name,
        description: @description,
        publisher_name: @publisher_name,
        publisher_url: @publisher_url,
        license: @license,
        frequency: @frequency
      }, files: []

      expect(request).to render_template(:new)
      expect(flash[:notice]).to eq("You must specify at least one dataset")
    end

    context 'with one file' do

      before(:each) do
        name = 'Test Data'
        description = Faker::Company.bs
        filename = 'test-data.csv'
        path = File.join(Rails.root, 'spec', 'fixtures', filename)

        Dataset.set_callback(:create, :after, :create_in_github)

        @files << {
          :title => name,
          :description => description,
          :file => Rack::Test::UploadedFile.new(path, "text/csv")
        }

        @repo = double(GitData)

        expect(@repo).to receive(:html_url) { nil }
        expect(@repo).to receive(:name) { nil }
        expect(@repo).to receive(:save)
      end

      it 'creates a dataset with one file' do
        expect(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        request = post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency
        }, files: @files

        expect(request).to redirect_to(datasets_path)
        expect(flash[:notice]).to eq("Dataset created sucessfully")
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end

      it 'creates a dataset in an organization' do
        organization = 'my-cool-organization'

        expect(GitData).to receive(:create).with(organization, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        request = post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
          owner: organization
        }, files: @files

        expect(request).to redirect_to(datasets_path)
        expect(flash[:notice]).to eq("Dataset created sucessfully")
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end

    end

    context('with a schema') do

      before(:each) do
        schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')
        @schema = Rack::Test::UploadedFile.new(schema_path, "text/csv")
      end

      it 'returns an error if the file does not match the schema' do
        path = File.join(Rails.root, 'spec', 'fixtures', 'invalid-schema.csv')
        schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')

        @files << {
          :title => 'My File',
          :description => 'My Description',
          :file => Rack::Test::UploadedFile.new(path, "text/csv")
        }

        request = post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
          schema: @schema
        }, files: @files

        expect(Dataset.count).to eq(0)
        expect(request).to render_template(:new)
        expect(flash[:notice]).to eq("Your file 'My File' does not match the schema you provided")
      end

      it 'creates sucessfully if the file matches the schema' do
        path = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')

        @files << {
          :title => 'My File',
          :description => 'My Description',
          :file => Rack::Test::UploadedFile.new(path, "text/csv")
        }

        request = post 'create', dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency,
          schema: @schema
        }, files: @files

        expect(request).to redirect_to(datasets_path)
        expect(flash[:notice]).to eq("Dataset created sucessfully")
        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)
      end

    end

    context 'via the API' do

      before(:each) do
        name = 'Test Data'
        description = Faker::Company.bs
        filename = 'test-data.csv'
        path = File.join(Rails.root, 'spec', 'fixtures', filename)

        Dataset.set_callback(:create, :after, :create_in_github)

        @repo = double(GitData)

        allow(GitData).to receive(:create).with(@user.github_username, @name, client: a_kind_of(Octokit::Client)) {
          @repo
        }

        @files << {
          :title => name,
          :description => description,
          :file => Rack::Test::UploadedFile.new(path, "text/csv")
        }
      end

      it 'creates a dataset with JSON' do
        expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:name) { 'my-cool-repo' }
        expect(@repo).to receive(:save)

        post 'create', :format => :json, dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency
        },
        files: @files,
        api_key: @user.api_key

        expect(Dataset.count).to eq(1)
        expect(@user.datasets.count).to eq(1)
        expect(@user.datasets.first.dataset_files.count).to eq(1)

        expect(response.body).to eq({
          "id": Dataset.first.id,
          "name":"My cool dataset",
          "url": "https://github.com/user-mc-user/my-cool-repo",
          "user_id":@user.id,
          "created_at": Dataset.first.created_at,
          "updated_at": Dataset.first.updated_at,
          "repo":"my-cool-repo",
          "description":"This is a description",
          "publisher_name":"Cool inc",
          "publisher_url":"http://example.com",
          "license":"OGL-UK-3.0",
          "frequency":"Monthly",
          "datapackage_sha": nil,
          "owner": nil,
          "gh_pages_url":"http://user-mcuser.github.io/my-cool-repo"
        }.to_json)
      end

      context('with a schema') do

        before(:each) do
          schema_path = File.join(Rails.root, 'spec', 'fixtures', 'schemas', 'good-schema.json')
          @schema = Rack::Test::UploadedFile.new(schema_path, "text/csv")
        end

        it 'creates a dataset sucessfully' do
          expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
          expect(@repo).to receive(:name) { 'my-cool-repo' }
          expect(@repo).to receive(:save)

          path = File.join(Rails.root, 'spec', 'fixtures', 'valid-schema.csv')

          files = [{
            :title => 'My File',
            :description => 'My Description',
            :file => Rack::Test::UploadedFile.new(path, "text/csv")
          }]

          post 'create', :format => :json, dataset: {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency,
            schema: @schema
          },
          files: files,
          api_key: @user.api_key

          expect(Dataset.count).to eq(1)
          expect(@user.datasets.count).to eq(1)
          expect(@user.datasets.first.dataset_files.count).to eq(1)
        end

        it 'errors is a file does not match the schema' do
          path = File.join(Rails.root, 'spec', 'fixtures', 'invalid-schema.csv')

          files = [{
            :title => 'My File',
            :description => 'My Description',
            :file => Rack::Test::UploadedFile.new(path, "text/csv")
          }]

          post 'create', :format => :json, dataset: {
            name: @name,
            description: @description,
            publisher_name: @publisher_name,
            publisher_url: @publisher_url,
            license: @license,
            frequency: @frequency,
            schema: @schema
          },
          files: files,
          api_key: @user.api_key

          expect(Dataset.count).to eq(0)
          expect(response.body).to eq({
            "errors": [
              "Your file 'My File' does not match the schema you provided"
            ]
          }.to_json)
        end

      end

      it 'skips the authenticity token if creating via the API' do
        expect(@repo).to receive(:html_url) { 'https://github.com/user-mc-user/my-cool-repo' }
        expect(@repo).to receive(:name) { 'my-cool-repo' }
        expect(@repo).to receive(:save)
        expect(controller).to_not receive(:verify_authenticity_token)

        post 'create', :format => :json, dataset: {
          name: @name,
          description: @description,
          publisher_name: @publisher_name,
          publisher_url: @publisher_url,
          license: @license,
          frequency: @frequency
        },
        files: @files,
        api_key: @user.api_key
      end

    end

  end

  describe 'edit' do

    it 'gets a file with a particular id' do
      sign_in @user
      dataset = create(:dataset, name: "Dataset", user: @user)

      get 'edit', id: dataset.id

      expect(assigns(:dataset)).to eq(dataset)
    end

    it 'returns 404 if the user does not own a particular dataset' do
      other_user = create(:user, name: "User 2", email: "other-user@user.com")
      dataset = create(:dataset, name: "Dataset", user: other_user)

      sign_in @user

      get 'edit', id: dataset.id

      expect(response.code).to eq("404")
    end

    it 'returns 404 if the user is not signed in' do
      dataset = create(:dataset, name: "Dataset", user: @user)

      get 'edit', id: dataset.id

      expect(response.code).to eq("403")
    end

  end

  describe 'update' do

    before(:each) do
      sign_in @user
      @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])
      @dataset.save
      @file = @dataset.dataset_files.first

      @dataset_hash = {
        name: "New name",
        description: "New description",
        publisher_name: "New Publisher",
        publisher_url: "http://new.publisher.com",
        license: "OGL-UK-3",
        frequency: "annual"
      }
    end

    context('successful update') do
      before(:each) do
        @repo = double(GitData)

        expect(Dataset).to receive(:where).with(id: @dataset.id.to_s, user_id: @user.id) { [@dataset] }
        expect(@dataset).to receive(:update_datapackage)
        expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
        expect(@repo).to receive(:save)
        Dataset.set_callback(:update, :after, :update_in_github)
      end

      context('with schema') do
        context 'with schema-compliant csv' do
          before(:each) do
            expect(@repo).to receive(:get_file) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'datapackage.json')) }
          end

          it 'updates a file in Github' do
            filename = 'valid-schema.csv'
            path = File.join(Rails.root, 'spec', 'fixtures', filename)
            file = Rack::Test::UploadedFile.new(path, "text/csv")

            expect(@file).to receive(:update_in_github)

            put 'update', id: @dataset.id, dataset: @dataset_hash, files: [{
                id: @file.id,
                file: file
            }]
          end

          context 'adds a new file in Github' do

            before :each do
              @file.file = nil

              @filename = 'valid-schema.csv'
              @path = File.join(Rails.root, 'spec', 'fixtures', @filename)
              @new_file = Rack::Test::UploadedFile.new(@path, "text/csv")

              file = build(:dataset_file, dataset: @dataset, file: nil)

              expect(DatasetFile).to receive(:new_file) { file }
              expect(file).to receive(:add_to_github)
            end

            it 'via a browser' do
              put 'update', id: @dataset.id, dataset: @dataset_hash, files: [
                {
                  id: @file.id,
                  title: "New title",
                  description: "New description"
                 },
                {
                  title: "New file",
                  description: "New file description",
                  file: @new_file
                }
              ]

              expect(@dataset.dataset_files.count).to eq(2)
            end

            it 'over the API' do
              put 'update', format: :json, id: @dataset.id, files: [
                {
                  id: @file.id,
                  title: "New title",
                  description: "New description"
                 },
                {
                  title: "New file",
                  description: "New file description",
                  file: @new_file
                }
              ]

              expect(@dataset.dataset_files.count).to eq(2)
              expect(JSON.parse(response.body)).to include (
                {
                  "name"=>"Dataset",
                  "gh_pages_url"=>"http://user-mcuser.github.io/"
                }
              )
              expect(response.code).to eq '201'
            end
          end
        end

      end

      context('without schema') do

        before(:each) do
          expect(@repo).to receive(:get_file) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'datapackage-without-schema.json')) }
        end

        it 'updates a dataset' do
          @file.file = nil

          put 'update', id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @file.id,
              title: "New title",
              description: "New description"
             }]

          expect(response).to redirect_to(datasets_path)
          @dataset.reload

          expect(@dataset.name).to eq("Dataset")
          expect(@dataset.description).to eq("New description")
          expect(@dataset.publisher_name).to eq("New Publisher")
          expect(@dataset.publisher_url).to eq("http://new.publisher.com")
          expect(@dataset.license).to eq("OGL-UK-3")
          expect(@dataset.frequency).to eq("annual")
          expect(@dataset.dataset_files.count).to eq(1)
          expect(@dataset.dataset_files.first.title).to eq("New title")
          expect(@dataset.dataset_files.first.description).to eq("New description")
        end

        it 'updates a file in Github' do
          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = Rack::Test::UploadedFile.new(path, "text/csv")

          expect(@file).to receive(:update_in_github)

          put 'update', id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @file.id,
              file: file
          }]
        end

        it 'adds a new file in Github' do
          @file.file = nil

          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = Rack::Test::UploadedFile.new(path, "text/csv")

          new_file = build(:dataset_file, dataset: @dataset, file: nil)

          expect(DatasetFile).to receive(:new_file) { new_file }
          expect(new_file).to receive(:add_to_github)

          put 'update', id: @dataset.id, dataset: @dataset_hash, files: [
            {
              id: @file.id,
              title: "New title",
              description: "New description"
             },
            {
              title: "New file",
              description: "New file description",
              file: file
            }
          ]

          expect(@dataset.dataset_files.count).to eq(2)
        end

      end

    end

    context('unsuccessful update') do

      context 'with non-compliant csv' do
        before(:each) do
          @repo = double(GitData)
          expect(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) { @repo }
          expect(@repo).to receive(:get_file) { File.read(File.join(Rails.root, 'spec', 'fixtures', 'datapackage.json')) }
        end

        it 'does not update a file in Github' do
          @file.file = nil
          filename = 'invalid-schema.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = Rack::Test::UploadedFile.new(path, "text/csv")

          expect(@file).to_not receive(:update_in_github)

          put 'update', id: @dataset.id, dataset: @dataset_hash, files: [{
              id: @file.id,
              file: file
          }]

          expect(request).to render_template(:edit)
          expect(flash[:notice]).to eq("Your file '#{@file.title}' does not match the schema you provided")
          expect(response.code).to eq '400'
        end

        context 'does not add new file in Github' do
          before :each do
            @file.file = nil

            @filename = 'invalid-schema.csv'
            @path = File.join(Rails.root, 'spec', 'fixtures', @filename)
            @new_file = Rack::Test::UploadedFile.new(@path, "text/csv")

            file = build(:dataset_file, dataset: @dataset, file: nil)

            expect(file).to_not receive(:add_to_github)
          end

          it 'with a browser' do

            put 'update', id: @dataset.id, dataset: @dataset_hash, files: [
              {
                id: @file.id,
                title: "New title",
                description: "New description"
               },
              {
                title: "New file",
                description: "New file description",
                file: @new_file
              }
            ]

            expect(@dataset.dataset_files.count).to eq(1)
            expect(request).to render_template(:edit)
            expect(flash[:notice]).to eq("Your file 'New file' does not match the schema you provided")
          end

          it 'over the API' do
            put 'update', format: :json, id: @dataset.id, dataset: @dataset_hash, files: [
              {
                id: @file.id,
                title: "New title",
                description: "New description"
               },
              {
                title: "New file",
                description: "New file description",
                file: @new_file
              }
            ]

            expect(JSON.parse(response.body)['errors'].first).to eq "Your file 'New file' does not match the schema you provided"
          end
        end
      end

    end

  end

  describe 'destroy' do
    it 'deletes a dataset' do
      sign_in @user

      @dataset = create(:dataset, user: @user)

      expect(Dataset).to receive(:where).with(id: @dataset.id.to_s, user_id: @user.id) {
        [
          @dataset
        ]
      }

      expect(@dataset).to receive(:fetch_repo)
      expect(@dataset).to receive(:destroy)

      request = delete 'destroy', id: @dataset.id
      expect(request).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Dataset '#{@dataset.name}' deleted sucessfully")
    end
  end

end
