require 'spec_helper'

describe 'datasets/_dataset.html.erb' do

  before(:each) do
    @user = create(:user, name: "user")
    @dataset = create(:dataset, name: "My Dataset", repo: "my-repo", user: @user)
  end

  it 'displays a single dataset' do
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
    expect(rendered).to match /<a href="http:\/\/user.github.io\/my-repo">My Dataset<\/a>/
  end

  it 'does not display the edit link when path is not the dashboard' do
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
    expect(rendered).to_not match /Edit/
  end

  it 'displays the edit link when in the dashboard' do
    controller.request.env['PATH_INFO'] = "/dashboard"
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
    expect(rendered).to match /<a class=\"btn btn-xs btn-warning\" href=\"\/datasets\/#{@dataset.id}\/edit\">Edit<\/a>/
  end

end
