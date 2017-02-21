require 'rails_helper'

describe UpdateDataset, vcr: { :match_requests_on => [:host, :method] } do

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

    expect(@worker).to receive(:get_dataset).with(@dataset.id, @user) {
      @dataset
    }
    expect(@worker).to receive(:jid) {
      "84855ffe6a7e1d6dacf6685e"
    }

    filename = 'valid-schema.csv'
    path = File.join(Rails.root, 'spec', 'fixtures', filename)

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
        'file' => url_with_stubbed_get_for(path)
      }
    ]
  end

  after(:each) do
    Dataset.set_callback(:update, :after, :update_dataset_in_github)
  end

  it 'sets a job id' do
    expect(@dataset).to receive(:report_status).with('beep-beep')

    @worker.perform(@dataset.id, @user.id, @dataset_params, @files, "channel_id" => "beep-beep")

    expect(@dataset.job_id).to eq("84855ffe6a7e1d6dacf6685e")
  end

  it 'reports success' do
    expect(@dataset).to receive(:report_status).with('beep-beep')

    dataset = @worker.perform(@dataset.id, @user.id, @dataset_params, @files, "channel_id" => "beep-beep")
  end

  context 'reports errors' do

    before(:each) do
      filename = 'schemas/bad-schema.json'
      path = File.join(Rails.root, 'spec', 'fixtures', filename)

      @bad_files = [
        {
          'title' => 'My File',
          'description' => Faker::Company.bs,
          'file' => url_with_stubbed_get_for(path)
        }
      ]
    end

    it 'to pusher' do
      mock_client = mock_pusher('beep-beep')
      expect(mock_client).to receive(:trigger).with('dataset_failed', instance_of(Array))

      @worker.perform(@dataset.id, @user.id, @dataset_params, @bad_files, "channel_id" => "beep-beep")
    end

    it 'to the database' do
      @worker.perform(@dataset.id, @user.id, @dataset_params, @bad_files)

      expect(Error.count).to eq(1)
      expect(Error.first.messages).to eq(["Dataset files is invalid", "Your file 'My File' does not appear to be a valid CSV. Please check your file and try again."])
    end
  end
end
