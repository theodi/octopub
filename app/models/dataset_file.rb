class DatasetFile < ActiveRecord::Base

  belongs_to :dataset

  after_create :add_to_github

  attr_accessor :tempfile

  def github_url
    "#{dataset.github_url}/data/#{filename}"
  end

  def gh_pages_url
    "#{dataset.gh_pages_url}/data/#{filename}"
  end

  private

    def add_to_github
      response = dataset.create_contents(filename, tempfile.read, "data")
      self.file_sha = response[:content][:sha]
      response = dataset.create_contents("#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data")
      self.view_sha = response[:content][:sha]
      save
    end

    def update_in_github(tempfile)
      response = dataset.update_contents(filename, tempfile.read, "data", file_sha)
      self.file_sha = response[:content][:sha]
      response = dataset.update_contents("#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data", view_sha)
      self.view_sha = response[:content][:sha]
      save
    end

end
