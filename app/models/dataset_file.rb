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
    "#{github_url}/commits/gh-pages/data/#{filename}"
  end

  private

    def add_to_github
      dataset.create_contents(filename, tempfile.read, "data")
    end

end
