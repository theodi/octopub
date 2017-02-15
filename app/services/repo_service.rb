class RepoService

  def create_repo(repo_owner, name, restricted, user)
      GitData.create(repo_owner, name, restricted: restricted, client: user.octokit_client)
  end

end
