require 'spec_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user, name: "User McUser", email: "user@user.com")
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
