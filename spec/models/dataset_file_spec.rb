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
      @tempfile = Rack::Test::UploadedFile.new(@path, "text/csv")

      @dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [@file])
    end

    it "adds a file to Github" do
      expect(@dataset).to receive(:create_contents).with("data/example.csv", File.read(@path))
      expect(@dataset).to receive(:create_contents).with("data/example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)

      @file.send(:add_to_github, @tempfile)
    end
  end

  context "update_in_github" do

    before(:each) do
      @file = create(:dataset_file, filename: "example.csv")
      @tempfile = Rack::Test::UploadedFile.new(@path, "text/csv")

      @dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [@file])
    end

    it "updates a file in Github" do
      expect(@dataset).to receive(:update_contents).with("data/example.csv", File.read(@path))
      expect(@dataset).to receive(:update_contents).with("data/example.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read)

      @file.send(:update_in_github, @tempfile)
    end
  end

  context "delete_from_github" do

    it "deletes a file from github" do
      file = create(:dataset_file, filename: "example.csv")
      dataset = create(:dataset, repo: "my-repo", user: @user, dataset_files: [file])

      expect(dataset).to receive(:delete_contents).with("example.csv")
      expect(dataset).to receive(:delete_contents).with("example.md")

      file.send(:delete_from_github, file)
    end

  end

  context "self.new_file" do

    before(:each) do
      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
      @tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

      @file = {
        "title" => 'My File',
        "file" => @tempfile,
        "description" => 'A description',
      }
    end

    it "creates a file in github" do
      created_file = create(:dataset_file)
      expect(DatasetFile).to receive(:new) { created_file }
      expect(created_file).to receive(:add_to_github).with(@tempfile)

      DatasetFile.new_file(@file)
    end

    it "creates a file" do
      expect_any_instance_of(DatasetFile).to receive(:add_to_github) {}

      file = DatasetFile.new_file(@file)

      expect(file.title).to eq(@file["title"])
      expect(file.filename).to eq(@tempfile.original_filename)
      expect(file.description).to eq(@file["description"])
      expect(file.mediatype).to eq("text/csv")
    end

  end

  context "self.update_file" do

    before(:each) do
      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
      tempfile = Rack::Test::UploadedFile.new(path, "text/csv")
      @file = create(:dataset_file)

      @new_file = {
        "id" => @file.id,
        "title" => 'My File',
        "file" => tempfile,
        "description" => 'A new description',
      }
    end

    it "updates a file" do
      expect(DatasetFile).to receive(:find) { @file }
      expect(@file).to receive(:update_file).with(@new_file)

      DatasetFile.update_file(@new_file)
    end

    it "returns nil if a file is not found" do
      allow_message_expectations_on_nil
      file = nil

      expect(DatasetFile).to receive(:find) { file }
      expect(file).to_not receive(:update_file)

      @new_file["id"] = 123

      file = DatasetFile.update_file(@new_file)

      expect(file).to eq(nil)
    end

  end

  context "update_file" do

    it "updates a file" do
      file = create(:dataset_file, filename: 'test-data.csv')

      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data.csv')
      tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

      new_file = {
        "id" => file.id,
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

    it "only updates the referenced file if a file is present" do
      file = create(:dataset_file)

      new_file = {
        "id" => file.id,
        "title" => 'My File',
        "description" => 'A new description',
      }

      expect(file).to_not receive(:update_in_github)
      file.update_file(new_file)

      expect(file.title).to eq(new_file["title"])
      expect(file.description).to eq(new_file["description"])
      expect(file.mediatype).to eq("text/csv")
    end

    it "deletes the old file if the filenames are different" do
      file = create(:dataset_file)

      path = File.join(Rails.root, 'spec', 'fixtures', 'test-data0.csv')
      tempfile = Rack::Test::UploadedFile.new(path, "text/csv")

      new_file = {
        "id" => file.id,
        "title" => 'My File',
        "file" => tempfile,
        "description" => 'A new description',
      }

      expect(file).to receive(:update_in_github).with(tempfile)
      expect(file).to receive(:delete_from_github)
      file.update_file(new_file)
    end

  end

end
