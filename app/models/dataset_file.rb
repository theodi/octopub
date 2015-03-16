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

  def history_url
    "#{dataset.github_url}/commits/gh-pages/data/#{filename}"
  end

  private

    def add_to_github
      dataset.create_contents(filename, tempfile.read, "data")
      dataset.create_contents("#{File.basename(filename, '.*')}.md", File.open(File.join(Rails.root, "extra", "html", "data_view.md")).read, "data")
    end

end
