require 'spec_helper'

describe 'datasets/_datasets.html.erb' do

  before(:each) do
    allow_any_instance_of(Dataset).to receive(:owner_avatar) {
      "http://example.org/avatar.png"
    }
    @datasets = []
  end

  it "should display a number of datasets" do
    user = create(:user, name: "user")

    5.times { |i| @datasets << create(:dataset, name: "My Dataset #{i}", repo: "my-repo", user: user) }

    render :partial => 'datasets/datasets.html.erb'

    page = Nokogiri::HTML(rendered)
    expect(page.css('tr').count).to eq(6)
  end

  it "should display a message if there are no datasets" do
    render :partial => 'datasets/datasets.html.erb'

    expect(rendered).to match /You currently have no datasets/
  end

end
