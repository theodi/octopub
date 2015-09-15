require 'spec_helper'

describe 'datasets/_dataset.html.erb' do

  it 'displays a single dataset' do
    user = create(:user, name: "user")
    dataset = create(:dataset, name: "My Dataset", repo: "my-repo", user: user)

    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => dataset}

    expect(rendered).to match /<li><a href="http:\/\/user.github.io\/my-repo">My Dataset<\/a><\/li>/
  end

end
