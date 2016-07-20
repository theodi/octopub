require 'spec_helper'

describe CreateDataset do

  it 'creates a dataset' do
    user = create(:user)
    worker = CreateDataset.new
    @dataset = build(:dataset, user: @user)

    expect(worker).to receive(:jid) {
      "84855ffe6a7e1d6dacf6685e"
    }

    expect(worker).to receive(:dataset) {
      @dataset
    }

    expect(@dataset).to receive(:report_status).with('foo-bar')

    worker.perform({
      name: "My Awesome Dataset",
      description: "An awesome dataset",
      publisher_name: "Awesome Inc",
      publisher_url: "http://awesome.com",
      license: "OGL-UK-3.0",
      frequency: "One-off",
    },
    [
      ActiveSupport::HashWithIndifferentAccess.new(
        title: 'My File',
        description: 'My description',
        file: fake_file(File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv'))
      )
    ],
    user.id, channel_id: 'foo-bar')

    expect(@dataset.job_id).to eq("84855ffe6a7e1d6dacf6685e")
  end

end
