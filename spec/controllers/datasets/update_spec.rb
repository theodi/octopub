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

  describe 'update' do

    before(:each) do
      sign_in @user
      @dataset = create(:dataset, name: "Dataset", user: @user, dataset_files: [
        create(:dataset_file, filename: 'test-data.csv')
      ])
      @dataset.save
      @file = @dataset.dataset_files.first

      @dataset_hash = {
      #  name: "New name",
        description: "New description",
        publisher_name: "New Publisher",
        publisher_url: "http://new.publisher.com",
        license: "OGL-UK-3",
        frequency: "annual"
      }
    end

    it 'queues a job when async is set to true' do
      expect {
        put 'update', id: @dataset.id, dataset: @dataset_hash, async: true, files: [{
          id: @file.id,
          title: "New title",
          description: "New description"
        }]
      }.to change(Sidekiq::Extensions::DelayedClass.jobs, :size).by(1)

      expect(response.code).to eq("202")
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
              @new_file = fake_file(@path)

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
            description: "New description"
          }]

          expect(response).to redirect_to(dashboard_path)
          @dataset.reload

          expect(@dataset.name).to eq("Dataset")
          expect(@dataset.description).to eq("New description")
          expect(@dataset.publisher_name).to eq("New Publisher")
          expect(@dataset.publisher_url).to eq("http://new.publisher.com")
          expect(@dataset.license).to eq("OGL-UK-3")
          expect(@dataset.frequency).to eq("annual")
          expect(@dataset.dataset_files.count).to eq(1)
          expect(@dataset.dataset_files.first.description).to eq("New description")
        end

        it 'updates a file in Github' do
          filename = 'test-data.csv'
          path = File.join(Rails.root, 'spec', 'fixtures', filename)
          file = fake_file(path)

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
          file = fake_file(path)

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
          file = fake_file(path)

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
            @new_file = fake_file(@path)

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

    it 'filters out empty file params' do

      files = [
        {
          id: @file.id,
          title: "New title",
          description: "New description"
        },
        {
          title: "New file",
          description: "New file description",
          file: "http://example.com/new-file.csv"
        },
        {
          title: "This should get binned"
        }
      ]

      expect(Dataset).to receive(:update_dataset).with(@dataset.id.to_s, @user.id, @dataset_hash.stringify_keys!, [
          {
            "id" => @file.id.to_s,
            "title" => "New title",
            "description" => "New description"
          },
          {
            "title" => "New file",
            "description" => "New file description",
            "file" => "http://example.com/new-file.csv"
          }
        ]
      ) { build(:dataset) }

      put 'update', id: @dataset.id, dataset: @dataset_hash, files: files

    end

  end

end
