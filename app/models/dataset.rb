class Dataset < ActiveRecord::Base

  belongs_to :user
  before_create :create_in_github

  private

    def create_in_github
      repo = user.octokit_client.create_repository(name)
      self.url = repo[:html_url]
    end

end
