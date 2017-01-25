require 'spec_helper'

describe CreateDataset do

  before(:each) do
    skip_dataset_callbacks!

    @worker = CreateDataset.new

    @dataset_params = {
      name: "My Awesome Dataset",
      description: "An awesome dataset",
      publisher_name: "Awesome Inc",
      publisher_url: "http://awesome.com",
      license: "OGL-UK-3.0",
      frequency: "One-off",
    }

    @files = [
      ActiveSupport::HashWithIndifferentAccess.new(
        title: 'My File',
        description: 'My description',
        file: fake_file(File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv'))
      )
    ]

    @user = create(:user)
  end

  after(:each) do
    set_dataset_callbacks!
  end

  it 'sets a job id' do
    @dataset = build(:dataset, user: @user)

    expect(@worker).to receive(:jid) {
      "84855ffe6a7e1d6dacf6685e"
    }

    expect(@worker).to receive(:new_dataset_for_user) { @dataset }
    expect(@dataset).to receive(:report_status).with('foo-bar')

    @worker.perform(@dataset_params, @files, @user.id, "channel_id" => 'foo-bar')

    expect(@dataset.job_id).to eq("84855ffe6a7e1d6dacf6685e")
  end

  it 'reports success' do
    mock_client = mock_pusher('beep-beep')
    expect(mock_client).to receive(:trigger).with('dataset_created', instance_of(Dataset))

    @worker.perform(@dataset_params, @files, @user.id, "channel_id" => 'beep-beep')
  end

  it 'creates a schema' do
    mock_client = mock_pusher('beep-beep')
    expect(mock_client).to receive(:trigger).with('dataset_created', instance_of(Dataset))
    example_schema_uri = 'http://my-schemas.org/1234/schema.json'
    @dataset_params[:schema] = example_schema_uri

    allow_any_instance_of(DatasetFile).to receive(:check_schema).and_return(nil)
    allow_any_instance_of(Dataset).to receive(:check_schema).and_return(nil)
    @worker.perform(@dataset_params, @files, @user.id, "channel_id" => 'beep-beep')
    expect(Dataset.count).to eq(1)
    expect(DatasetSchema.count).to eq(1)
    expect(DatasetSchema.first.url_in_s3).to eq example_schema_uri
  end

  it 'reports errors' do
    filename = 'schemas/bad-schema.json'
    path = File.join(Rails.root, 'spec', 'fixtures', filename)

    files = [
      {
        'title' => 'My File',
        'description' => Faker::Company.bs,
        'file' => fake_file(path)
      }
    ]

    mock_client = mock_pusher('beep-beep')
    expect(mock_client).to receive(:trigger).with('dataset_failed', instance_of(Array))

    @worker.perform(@dataset_params, files, @user.id, "channel_id" => 'beep-beep')
  end

  it 'saves errors to the database' do
    expect(@worker).to receive(:jid) {
      "84855ffe6a7e1d6dacf6685e"
    }

    filename = 'schemas/bad-schema.json'
    path = File.join(Rails.root, 'spec', 'fixtures', filename)

    files = [
      {
        'title' => 'My File',
        'description' => Faker::Company.bs,
        'file' => fake_file(path)
      }
    ]

    @worker.perform(@dataset_params, files, @user.id)

    error = Error.find_by_job_id('84855ffe6a7e1d6dacf6685e')

    expect(error).to_not eq(nil)
    expect(error.messages).to eq([
      "Dataset files is invalid",
      "Your file 'My File' does not appear to be a valid CSV. Please check your file and try again."
    ])
  end

end
