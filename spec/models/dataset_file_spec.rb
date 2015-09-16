require 'spec_helper'

describe DatasetFile do

  before(:each) do
    @user = create(:user, name: "user-mcuser", email: "user@user.com")
    @path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
  end

  it "generates the correct urls" do
    file = create(:dataset_file, filename: "example.csv")
    dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [file])

    expect(file.github_url).to eq("http://github.com/user-mcuser/my-repo/data/example.csv")
    expect(file.gh_pages_url).to eq("http://user-mcuser.github.io/my-repo/data/example.csv")
  end

  it "adds a file to Github" do
    file = build(:dataset_file, filename: "example.csv")
    file.tempfile = Rack::Test::UploadedFile.new(@path, "text/csv")

    dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [file])

    expect(dataset).to receive(:create_contents).with("example.csv", File.read(@path), "data") { { content: {} } }
    expect(dataset).to receive(:create_contents).with("example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data") { { content: {} } }

    file.send(:add_to_github)
  end

  it "sets the sha after adding to Github", :vcr do
    file = build(:dataset_file, filename: "example.csv")
    file.tempfile = Rack::Test::UploadedFile.new(@path, "text/csv")

    dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [file])

    expect(dataset).to receive(:create_contents).with("example.csv", File.read(@path), "data") { { content: { sha: "sha1"} } }
    expect(dataset).to receive(:create_contents).with("example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data") { { content: { sha: "sha2"} } }

    file.send(:add_to_github)

    expect(file.file_sha).to eq("sha1")
    expect(file.view_sha).to eq("sha2")
  end

end
