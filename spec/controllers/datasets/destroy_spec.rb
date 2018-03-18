require 'rails_helper'

describe DatasetsController, type: :controller do

  describe 'basic destruction' do

    before :each do
      @user = create(:user)
      sign_in @user
    end

    it 'deletes a public github repo dataset' do
      sign_in @user

      @dataset = create(:dataset, user: @user)

      expect(Dataset).to receive(:find).with(@dataset.id.to_s) {
        @dataset
      }

      expect(RepoService).to receive(:fetch_repo)
      expect(@dataset).to receive(:destroy)

      request = delete :destroy, params: { id: @dataset.id }
      expect(request).to redirect_to(dashboard_path)
    end

    it 'deletes a private github repo dataset' do

      @dataset = create(:dataset, user: @user, publishing_method: :github_private)

      expect(Dataset).to receive(:find).with(@dataset.id.to_s) {
        @dataset
      }

      expect(RepoService).to receive(:fetch_repo)
      expect(@dataset).to receive(:destroy)

      request = delete :destroy, params: { id: @dataset.id }
      expect(request).to redirect_to(dashboard_path)
    end

    it 'deletes a private local repo dataset' do

      @dataset = create(:dataset, user: @user, publishing_method: :local_private)

      expect(Dataset).to receive(:find).with(@dataset.id.to_s) {
        @dataset
      }

      expect(RepoService).to_not receive(:fetch_repo)
      expect(@dataset).to receive(:destroy)

      request = delete :destroy, params: { id: @dataset.id }
      expect(request).to redirect_to(dashboard_path)
    end

    it 'deletes a public github repo dataset even if it cannot find the repo' do
      @dataset = create(:dataset, user: @user)
      expect(Dataset).to receive(:find).with(@dataset.id.to_s) { @dataset }

      expect(RepoService).to receive(:fetch_repo).and_raise Octokit::NotFound
      expect(@dataset).to receive(:destroy)

      request = delete :destroy, params: { id: @dataset.id }
      expect(request).to redirect_to(dashboard_path)
    end
  end

  describe 'permissions' do

    before :each do
      @user = create(:user)
      @admin = create(:admin)
      @other_user = create(:user)
    end

    it "cannot delete another user's dataset" do
      @dataset = create(:dataset, user: @other_user)
      expect(Dataset.count).to eq 1

      sign_in @user

      delete :destroy, params: { id: @dataset.id }
      expect(response.code).to eq("403")
      expect(Dataset.count).to eq 1
    end

    it "admin can delete another user's dataset" do
      @dataset = create(:dataset, user: @other_user)
      expect(Dataset.count).to eq 1

      sign_in @admin

      # Mocks
      allow(Dataset).to receive(:find).with(@dataset.id.to_s) {
        @dataset
      }
      allow(RepoService).to receive(:fetch_repo)

      expect(@dataset).to receive(:destroy).and_call_original
      delete :destroy, params: { id: @dataset.id }
      expect(response.code).to eq("302")
      expect(Dataset.count).to eq 0
    end

  end


end
