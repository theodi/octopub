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

  context "self.update_file" do

    before(:each) do
      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
      tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

      @new_file = {
        "title" => 'My File',
        "file" => tempfile,
        "description" => 'A new description',
      }
    end

    it "updates a file" do
      file = create(:dataset_file)

      expect(DatasetFile).to receive(:find) { file }
      expect(file).to receive(:update_file).with(@new_file)

      DatasetFile.update_file(file.id, @new_file)
    end

    it "returns nil if a file is not found" do
      allow_message_expectations_on_nil
      file = nil

      expect(DatasetFile).to receive(:find) { file }
      expect(file).to_not receive(:update_file)

      file = DatasetFile.update_file("123", @new_file)

      expect(file).to eq(nil)
    end

  end

  context "update_file" do

    it "updates a file" do
      file = create(:dataset_file)

      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
      tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

      new_file = {
        "title" => 'My File',
        "file" => tempfile,
        "description" => 'A new description',
      }

      expect(file).to receive(:update_in_github).with(tempfile)
      file.update_file(new_file)

      expect(file.title).to eq(new_file["title"])
      expect(file.filename).to eq(tempfile.original_filename)
      expect(file.description).to eq(new_file["description"])
      expect(file.mediatype).to eq("text/csv")
    end

  end

end
