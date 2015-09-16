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

  context "add_to_github" do

    before(:each) do
      @file = build(:dataset_file, filename: "example.csv")
      @file.tempfile = Rack::Test::UploadedFile.new(@path, "text/csv")

      @dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [@file])
    end

    it "adds a file to Github" do
      expect(@dataset).to receive(:create_contents).with("example.csv", File.read(@path), "data") { { content: {} } }
      expect(@dataset).to receive(:create_contents).with("example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data") { { content: {} } }

      @file.send(:add_to_github)
    end

    it "sets the sha", :vcr do
      expect(@dataset).to receive(:create_contents).with("example.csv", File.read(@path), "data") { { content: { sha: "sha1"} } }
      expect(@dataset).to receive(:create_contents).with("example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data") { { content: { sha: "sha2"} } }

      @file.send(:add_to_github)

      expect(@file.file_sha).to eq("sha1")
      expect(@file.view_sha).to eq("sha2")
    end
  end

  context "update_in_github" do

    before(:each) do
      @file = create(:dataset_file, filename: "example.csv", file_sha: "abbsdfsdfsdfsdvs", view_sha: "fgdfdgdfgdfgf")
      @tempfile = Rack::Test::UploadedFile.new(@path, "text/csv")

      @dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [@file])
    end

    it "updates a file in Github" do
      expect(@dataset).to receive(:update_contents).with("example.csv", File.read(@path), "data", @file.file_sha) { { content: {} } }
      expect(@dataset).to receive(:update_contents).with("example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data", @file.view_sha) { { content: {} } }

      @file.send(:update_in_github, @tempfile)
    end

    it "sets the new sha" do
      expect(@dataset).to receive(:update_contents).with("example.csv", File.read(@path), "data", @file.file_sha) { { content: { sha: "sha1"} } }
      expect(@dataset).to receive(:update_contents).with("example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data", @file.view_sha) { { content: { sha: "sha2"} } }

      @file.send(:update_in_github, @tempfile)

      expect(@file.file_sha).to eq("sha1")
      expect(@file.view_sha).to eq("sha2")
    end

  end

end
