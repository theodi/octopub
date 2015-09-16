require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
    Dataset.skip_callback(:create, :before, :create_in_github)
    DatasetFile.skip_callback(:create, :after, :add_to_github)
    allow_any_instance_of(Dataset).to receive(:create_files) { nil }
  end

  after(:each) do
    Dataset.set_callback(:create, :before, :create_in_github)
    DatasetFile.set_callback(:create, :after, :add_to_github)
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
  end

  describe 'new dataset' do
    it 'initializes a new dataset' do
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

    it 'creates a dataset with one file' do
      name = 'Test Data'
      description = Faker::Company.bs
      filename = 'test-data.csv'
      path = File.join(Rails.root, 'spec', 'fixtures', filename)

      @files << {
        :title => name,
        :description => description,
        :file => Rack::Test::UploadedFile.new(path, "text/csv")
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

      expect(response.code).to eq("404")
    end

  end

end
