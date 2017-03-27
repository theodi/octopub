class GitData

  attr_reader :full_name, :html_url, :name

  def self.create(owner, repo_name, options = {})
    client = options[:client]
    restricted = options[:restricted] || false
    if client.user[:login].downcase == owner.downcase
      repo = client.create_repository(repo_name.parameterize, private: restricted, auto_init: true)
    else
      repo = client.create_repository(repo_name.parameterize, private: restricted, auto_init: true, organization: owner)
    end
    # Create repo that auto initializes
    full_name = full_name(owner, repo_name)
    # Get the current branch info
    branch_data = client.branch full_name, 'master'
    # Create a gh-pages branch
    client.create_ref(full_name, 'heads/gh-pages', branch_data.commit.sha)
    # Make the gh-pages branch the default
    client.edit_repository(full_name, default_branch: 'gh-pages')
    new(client, repo)
  rescue Octokit::UnprocessableEntity # 422 error code
    # Here, means that private repositories aren't available
    # so return nil
    nil
  end

  def self.find(owner, repo_name, options = {})
    client = options[:client]
    repo = client.repository(full_name(owner, repo_name))
    new(client, repo, true)
  end

  def self.full_name(owner, repo_name)
    "#{owner.parameterize}/#{repo_name.parameterize}"
  end

  def initialize(client, repo, build_base = false)
    @client, @repo = client, repo
    @full_name = @repo.full_name
    @html_url = @repo.html_url
    @name = @repo.name
    if build_base === true
      tree = tree_data(base_tree)
      tree.each { |t| append_to_tree(t[:path], t[:sha]) if t[:type] == 'blob' }
    end
  end

  def add_file(filename, file_contents)
    blob_sha = blob_sha(file_contents)
    append_to_tree(filename, blob_sha)
  end

  def update_file(filename, file_contents)
    blob_sha = blob_sha(file_contents)
    update_tree(filename, blob_sha)
  end

  def delete_file(filename)
    tree.delete_if { |item| item["path"] == filename }
    @base_tree = false
  end

  def get_file(filename)
    file = @client.contents(full_name, path: filename)
    Base64.decode64(file[:content])
  end

  def save
    @client.update_ref(full_name, "heads/gh-pages", commit)
  end

  def delete
    @client.delete_repository(@full_name)
  end

  def make_public
    @client.update_repository(@full_name, restricted: false)
  end

  private

    def commit
     branch_data = @client.branch @full_name, 'gh-pages'
     latest_commit = branch_data.commit.sha
     commit = @client.create_commit @full_name, "Update #{DateTime.now.to_s} [ci skip]",
              create_tree.sha, latest_commit
     commit.sha
    end

    def blob_sha(content)
      @client.create_blob(@full_name, content, 'utf-8')
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
      item = tree.find { |found_item| found_item["path"] == filename }
      item["sha"] = blob_sha
    end

    def create_tree
      if @base_tree === false
        @client.create_tree(@full_name, tree)
      else
        @client.create_tree(@full_name, tree, base_tree: base_tree)
      end
    end

    def base_tree
      @client.refs(full_name).first.object.sha
    end

    def tree_data(sha)
      @client.tree(full_name, sha, recursive: true).tree
    end

end
