require 'spec_helper'

describe 'datasets/_datasets.html.erb' do

  it "should display a number of datasets" do
    user = create(:user, name: "user")
    @datasets = []

    5.times { |i| @datasets << create(:dataset, name: "My Dataset #{i}", repo: "my-repo", user: user) }

    render :partial => 'datasets/datasets.html.erb'

    5.times { |i| expect(rendered).to match /My Dataset #{i}/ }
  end

  it "should display a message if there are no datasets" do
    render :partial => 'datasets/datasets.html.erb'

    expect(rendered).to match /You currently have no datasets/
  end

end
