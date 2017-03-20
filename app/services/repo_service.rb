class RepoService

  attr_accessor :repo

  def initialize(repo)
    Rails.logger.info "Repo service initialised"
    @repo = repo
  end

  def self.create_repo(repo_owner, name, restricted, user)
    GitData.create(repo_owner, name, restricted: restricted, client: user.octokit_client)
  end

  def add_file(filename, file)
    @repo.add_file(filename, file) if @repo
  end

  def update_file(filename, file)
    @repo.update_file(filename, file) if @repo
  end

  def save
    @repo.save
  end

  def self.fetch_repo(dataset)
    repo = nil
    client = dataset.user.octokit_client
    begin
      Rails.logger.info "Repo service: in fetch_repo, look it up"
      repo = GitData.find(dataset.repo_owner, dataset.name, client: client)
    rescue Octokit::NotFound
      Rails.logger.info "in fetch_repo - not found"
    end
    repo
  end
end
