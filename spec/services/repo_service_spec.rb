require 'rails_helper'

describe RepoService do

  let(:user) { create(:user) }
  let(:dataset) { create(:dataset, user: user, repo: "repo") }
  let(:git_data) { double(GitData) }

  it "fetches a repo for a dataset when repo exists" do
    expect(GitData).to receive(:find).with(user.github_username, dataset.name, client: a_kind_of(Octokit::Client)) { git_data }
    expect( RepoService.fetch_repo(dataset)).to eq(git_data)
  end

  it 'returns nil if there is no repo' do
    expect(GitData).to receive(:find).with(user.github_username, dataset.name, client: a_kind_of(Octokit::Client)).and_raise(Octokit::NotFound)
    expect{ RepoService.fetch_repo(dataset)}.to raise_exception(Octokit::NotFound)
  end
end
