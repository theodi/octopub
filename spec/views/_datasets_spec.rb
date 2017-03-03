require 'rails_helper'

describe 'datasets/_datasets.html.erb' do

  before(:each) do
    @user = create(:user, name: "user")
  end

  it "should display a number of datasets" do
    5.times do |i|
      create(:dataset,
        name: "My Dataset #{i}",
        repo: "my-repo",
        user: @user,
        owner_avatar: "http://example.org/avatar.png"
      )
    end
    @datasets = Dataset.order(created_at: :desc)
    render :partial => 'datasets/datasets.html.erb'

    page = Nokogiri::HTML(rendered)
    expect(page.css('tr').count).to eq(6)
  end

  it "should display a message if there are no datasets" do
    @datasets = Dataset.order(created_at: :desc)
    render :partial => 'datasets/datasets.html.erb'

    expect(rendered).to match /You currently have no datasets/
  end

end
