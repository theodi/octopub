class GitData

  def initialize(client, repo_name, username)
    @client, @repo_name, @username = client, repo_name.parameterize, username
  end

  def commit
   branch_data = @client.branch full_name, 'gh-pages'
   latest_commit = branch_data.commit.sha
   commit = @client.create_commit full_name, "Update #{DateTime.now.to_s} [ci skip]",
            create_tree.sha, latest_commit
   commit.sha
  end

  def push
    @client.update_ref(full_name, "heads/gh-pages", commit)
  end

  def add_file(filename, file_contents)
    blob_sha = blob_sha(file_contents)
    append_to_tree(filename, blob_sha)
  end

  def update_file(filename, file_contents)
    blob_sha = blob_sha(file_contents)
    update_tree(filename, blob_sha)
  end

  def blob_sha(content)
    @client.create_blob(full_name, content, 'utf-8')
  end

  def tree
    @tree ||= []
  end

  def append_to_tree(filename, blob_sha)
    tree << {
      "path" => filename,
      "mode" => "100644",
      "type" => "blob",
      "sha" => blob_sha
    }
  end

  def update_tree(filename, blob_sha)
    item = tree.find { |item| item[:path] == filename }
    item[:sha] = blob_sha
  end

  def create_tree
    @client.create_tree(full_name, tree, base_tree: base_tree)
  end

  def base_tree
    @client.refs(full_name).first.object.sha
  end

  def tree_data(sha)
    tree = @client.tree(full_name, sha, recursive: true).tree.map { |r| r.to_h }
    tree.each { |h| h.delete(:size) }
    tree
  end

  def create
    # Create repo that auto initializes
    @repo = @client.create_repository(@repo_name, auto_init: true)
    # Get the current branch info
    branch_data = @client.branch full_name, 'master'
    # Create a gh-pages branch
    @client.create_ref(full_name, 'heads/gh-pages', branch_data.commit.sha)
    # Make the gh-pages branch the default
    @client.edit_repository(full_name, default_branch: 'gh-pages')
  end

  def find
    @repo = @client.repository(full_name)
    @tree = tree_data(base_tree)
  end

  def full_name
    "#{@username}/#{@repo_name}"
  end

  def html_url
    @html_url || @repo.html_url
  end

end
