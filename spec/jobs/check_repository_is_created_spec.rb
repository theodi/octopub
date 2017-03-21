require 'rails_helper'

describe CheckRepositoryIsCreated do

  before(:each) do
    @worker = CheckRepositoryIsCreated.new
    @user = create(:user)
    name = "My Awesome Dataset"
    full_name = "my-cool-organization/#{name.parameterize}"
    @dataset = create(:dataset, user: @user, name: name)

    @html_url = "http://github.com/#{@user.name}/#{name.parameterize}"
    @obj = double(GitData)

    allow(GitData).to receive(:find).with(@user.github_username, @dataset.name, client: a_kind_of(Octokit::Client)) {
      expect(@obj).to receive(:html_url) { @html_url }
      expect(@obj).to receive(:name) { name.parameterize }
      expect(@obj).to receive(:full_name) { full_name }
      @obj
    }
  end

  it 'and updates columns' do
    @worker.perform(@dataset.id)
    @dataset.reload
    expect(@dataset.url).to eq(@html_url)
  end
end
