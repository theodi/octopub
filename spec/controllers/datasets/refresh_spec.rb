require 'spec_helper'

describe DatasetsController, type: :controller do

  context 'refresh' do

    before(:each) do
      user = create(:user)
      sign_in user
    end

    it 'queues a job to Sidekiq' do
      expect {
        get 'refresh', channel_id: 'my_channel'
      }.to change(Sidekiq::Extensions::DelayedClass.jobs, :size).by(1)
    end

    it 'returns a status of 202' do
      response = get 'refresh', channel_id: 'my_channel'

      expect(response.code).to eq("202")
    end

  end

end
