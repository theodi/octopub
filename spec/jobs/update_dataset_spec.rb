require 'rails_helper'

describe UpdateDataset, vcr: { :match_requests_on => [:host, :method] } do

  let(:filename) { 'valid-schema.csv' }
  let(:storage_key) { filename }
  let(:url_for_data_file) { url_with_stubbed_get_for_storage_key(storage_key, filename) }
  let(:good_schema_path) { get_fixture_schema_file('good-schema.json') }

  before(:each) do
    skip_callback_if_exists( Dataset, :update, :after, :update_dataset_in_github)
    @worker = UpdateDataset.new
    @user = create(:user)
    @dataset = create(:dataset, name: "My Awesome Dataset",
                     description: "An awesome dataset",
                     publisher_name: "Awesome Inc",
                     publisher_url: "http://awesome.com",
                     license: "OGL-UK-3.0",
                     frequency: "One-off",
                     user: @user)

    expect(@worker).to receive(:get_dataset).with(@dataset.id) { @dataset }
    expect(@worker).to receive(:jid) { "84855ffe6a7e1d6dacf6685e" }

    @dataset_params = {
      description: "Another awesome dataset",
      publisher_name: "Awesome Incorporated",
      publisher_url: "http://awesome.com/awesome",
      license: "OGL-UK-3.0",
      frequency: "One-off"
    }

    @files = [
      {
        'title' => 'My File',
        'description' => Faker::Company.bs,
        'file' => url_for_data_file,
        'storage_key' => storage_key
      }
    ]
  end

  after(:each) do
    Dataset.set_callback(:update, :after, :update_dataset_in_github)
  end

  it 'sets a job id' do
    expect(@dataset).to receive(:report_status).with('beep-beep', :update)
    expect_any_instance_of(JekyllService).to receive(:add_to_github)
    expect_any_instance_of(JekyllService).to receive(:add_jekyll_to_github)
    expect_any_instance_of(JekyllService).to receive(:push_to_github)

    @worker.perform(@dataset.id, @dataset_params, @files, "channel_id" => "beep-beep")

    expect(@dataset.job_id).to eq("84855ffe6a7e1d6dacf6685e")
  end

  it 'reports success' do
    expect(@dataset).to receive(:report_status).with('beep-beep', :update)
    expect_any_instance_of(JekyllService).to receive(:add_to_github)
    expect_any_instance_of(JekyllService).to receive(:add_jekyll_to_github)
    expect_any_instance_of(JekyllService).to receive(:push_to_github)

    dataset = @worker.perform(@dataset.id, @dataset_params, @files, "channel_id" => "beep-beep")
  end

  it "reports success and doesn't push to GitHub it private" do
    @dataset.update_columns(publishing_method: :local_private)
    expect(@dataset).to receive(:report_status).with('beep-beep', :update)
    expect_any_instance_of(JekyllService).to_not receive(:add_to_github)
    expect_any_instance_of(JekyllService).to_not receive(:add_jekyll_to_github)
    expect_any_instance_of(JekyllService).to_not receive(:push_to_github)

    dataset = @worker.perform(@dataset.id, @dataset_params, @files, "channel_id" => "beep-beep")
  end

  context 'with legacy files missing a storage_key' do
    
    it 'updates metadata successfully' do
      file = create(:dataset_file)
      file.storage_key = nil
      file.save!(validate: false)
      @dataset.dataset_files << file
      
      expect(@dataset).to receive(:report_status).with('beep-beep', :update)

      files = [
        {
          'id' => file.id,
          'title' => 'My New Filename',
          'description' => Faker::Company.bs
        }
      ]

      @worker.perform(@dataset.id, @dataset_params, files, "channel_id" => "beep-beep")
    end
    
  end

  context 'reports errors' do

    let(:filename) { 'datapackage.json' }
    let(:storage_key) { filename }
    let(:url_for_data_file) { url_with_stubbed_get_for_storage_key(storage_key, filename) }

    before(:each) do

      @bad_files = [
        {
          'title' => 'My File',
          'description' => Faker::Company.bs,
          'file' => url_for_data_file,
          'storage_key' => storage_key
        }
      ]
    end

    it 'to pusher' do
      mock_client = mock_pusher('beep-beep')
      expect(mock_client).to receive(:trigger).with('dataset_failed', instance_of(Array))
      expect_any_instance_of(JekyllService).to receive(:push_to_github)

      @worker.perform(@dataset.id, @dataset_params, @bad_files, "channel_id" => "beep-beep")
    end

    it 'to the database' do
      expect_any_instance_of(JekyllService).to receive(:push_to_github)
      @worker.perform(@dataset.id, @dataset_params, @bad_files)

      expect(Error.count).to eq(1)
      expect(Error.first.messages).to eq(["Dataset files is invalid", "Your file 'My File' does not appear to be a valid CSV. Please check your file and try again."])
    end
  end
end
