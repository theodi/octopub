require 'rails_helper'

describe DatasetsController, type: :controller do

  before(:each) do
    @user = create(:user)
    sign_in @user
  end

  describe 'destroy' do
    it 'deletes a public github repo dataset' do

      @dataset = create(:dataset, user: @user)

      expect(Dataset).to receive(:find).with(@dataset.id.to_s) {
        @dataset
      }

      expect(RepoService).to receive(:fetch_repo)
      expect(@dataset).to receive(:destroy)

      request = delete :destroy, params: { id: @dataset.id }
      expect(request).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Dataset '#{@dataset.name}' deleted sucessfully")
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
      expect(flash[:notice]).to eq("Dataset '#{@dataset.name}' deleted sucessfully")
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
      expect(flash[:notice]).to eq("Dataset '#{@dataset.name}' deleted sucessfully")
    end

    it 'deletes a public github repo dataset even if it cannot find the repo' do
      @dataset = create(:dataset, user: @user)
      expect(Dataset).to receive(:find).with(@dataset.id.to_s) { @dataset }

      expect(RepoService).to receive(:fetch_repo).and_raise Octokit::NotFound
      expect(@dataset).to receive(:destroy)

      request = delete :destroy, params: { id: @dataset.id }
      expect(request).to redirect_to(dashboard_path)
      expect(flash[:notice]).to eq("Dataset '#{@dataset.name}' deleted sucessfully - but we could not find the repository in GitHub to delete")
    end
  end
end
