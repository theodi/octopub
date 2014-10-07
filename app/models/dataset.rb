class Dataset < ActiveRecord::Base

  belongs_to :user
  before_create :create_in_github

  def add_files(files)
    clear_empty_files(files)
    files.each do |file|
      user.octokit_client.create_contents(
                                          repo,
                                          file["file"].original_filename,
                                          "Adding #{file["file"].original_filename}",
                                          file["file"].tempfile.read
                                          )
    end
  end

  private

    def clear_empty_files(files)
      files.delete_if { |f| f["file"].nil? }
    end

    def create_in_github
      repo = user.octokit_client.create_repository(name)
      self.url = repo[:html_url]
      self.repo = repo[:full_name]
    end

end
