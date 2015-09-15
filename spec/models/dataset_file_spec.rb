require 'spec_helper'

describe DatasetFile do

  before(:each) do
    @user = create(:user, name: "user-mcuser", email: "user@user.com")
  end

  it "generates the correct urls" do
    file = create(:dataset_file, filename: "example.csv")
    dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [file])

    expect(file.github_url).to eq("http://github.com/user-mcuser/my-repo/data/example.csv")
    expect(file.gh_pages_url).to eq("http://user-mcuser.github.io/my-repo/data/example.csv")
  end

  it "adds a file to Github" do
    path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')

    file = build(:dataset_file, filename: "example.csv")
    file.tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

    dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [file])

    expect(dataset).to receive(:create_contents).with("example.csv", File.read(path), "data")
    expect(dataset).to receive(:create_contents).with("example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data")

    file.send(:add_to_github)
  end

end
