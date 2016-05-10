require 'spec_helper'
require 'git_data'

describe GitData, :vcr do

  before(:all) do
    @client = Octokit::Client.new :access_token => ENV['GITHUB_TOKEN']
    @name = 'My Awesome Repo'
    @username = ENV['GITHUB_USER']
    @repo_name = "#{ENV['GITHUB_USER']}/my-awesome-repo"
    @git_data = GitData.new(@client, @name, @username)
  end

  context '#create', :delete_repo do
    before(:all) do
      @git_data.create
    end

    it 'creates a repo' do
      expect(@client.repository?(@repo_name)).to eq(true)
    end

    it 'sets gh-pages as the default branch' do
      expect(@client.repository(@repo_name).default_branch).to eq('gh-pages')
    end

    it 'sets the html_url' do
      expect(@git_data.html_url).to eq('https://github.com/git-data-publisher/my-awesome-repo')
    end
  end

  context '#find', :delete_repo do
    before(:all) do
      @git_data.create
    end

    it 'finds the repo' do
      repo = @git_data.find
      expect(repo.name).to eq('my-awesome-repo')
    end
  end

  context '#add_file', :delete_repo do

    before(:all) do
      @git_data.create
      @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
    end

    it 'creates a sha for a blob' do
      expect(@git_data.blob_sha(@file)).to eq('c46d38c374cd81824aeb74476abc53293db77b08')
    end

    it 'appends to a tree' do
      @git_data.instance_variable_set(:"@tree", nil)
      @git_data.add_file('my-awesome-file.csv', @file)

      expect(@git_data.tree).to eq([
        {
          "path" => 'my-awesome-file.csv',
          "mode" => "100644",
          "type" => "blob",
          "sha" => 'c46d38c374cd81824aeb74476abc53293db77b08'
        }
      ])
    end

    it 'appends multiple files to a tree' do
      @git_data.instance_variable_set(:"@tree", nil)
      @git_data.add_file('my-awesome-file.csv', @file)
      @git_data.add_file('my-other-awesome-file.csv', @file)

      expect(@git_data.tree).to eq([
        {
          "path" => 'my-awesome-file.csv',
          "mode" => "100644",
          "type" => "blob",
          "sha" => 'c46d38c374cd81824aeb74476abc53293db77b08'
        },
        {
          "path" => 'my-other-awesome-file.csv',
          "mode" => "100644",
          "type" => "blob",
          "sha" => 'c46d38c374cd81824aeb74476abc53293db77b08'
        }
      ])
    end
  end

  context 'adding files' do

    before(:each) do
      @git_data.create
      @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
      @git_data.instance_variable_set(:"@tree", nil)
    end

    after(:each) do
      @client.delete_repository(@repo_name)
    end

    it 'adds a single file' do
      @git_data.add_file('my-awesome-file.csv', @file)
      @git_data.push

      tree = @client.tree(@repo_name, @git_data.base_tree)

      expect(tree.tree.count).to eq(2)
      expect(tree.tree.last.path).to eq('my-awesome-file.csv')
    end

    it 'adds multiple files' do
      @git_data.add_file('my-awesome-file.csv', @file)
      @git_data.add_file('my-other-awesome-file.csv', @file)
      @git_data.push

      tree = @client.tree(@repo_name, @git_data.base_tree)

      expect(tree.tree.count).to eq(3)
      expect(tree.tree[1].path).to eq('my-awesome-file.csv')
      expect(tree.tree[2].path).to eq('my-other-awesome-file.csv')
    end

    it 'adds a file within a folder' do
      @git_data.add_file('data/my-awesome-file.csv', @file)
      @git_data.push

      tree = @client.tree(@repo_name, @git_data.base_tree)

      expect(tree.tree.count).to eq(2)
      expect(tree.tree.last.path).to eq('data')
    end

    it 'adds muliple files within a folder' do
      @git_data.add_file('data/my-awesome-file.csv', @file)
      @git_data.add_file('data/my-other-awesome-file.csv', @file)
      @git_data.push

      tree = @client.tree(@repo_name, @git_data.base_tree)

      expect(tree.tree.count).to eq(2)
      expect(tree.tree.last.path).to eq('data')
    end
  end

  it 'updates a file', :delete_repo do
    @git_data.create
    @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
    @git_data.add_file('my-awesome-file.csv', @file)
    @git_data.push

    @new_data = GitData.new(@client, @name, @username)

    @new_data.find
    new_content = "new,content,here\r\n1,2,3"

    @new_data.update_file('my-awesome-file.csv', new_content)
    @new_data.push

    tree = @client.tree(@repo_name, @new_data.base_tree)
    content = @client.contents(@repo_name, path: 'my-awesome-file.csv', ref: 'heads/gh-pages').content

    expect(tree.tree.count).to eq(2)
    expect(tree.tree.last.path).to eq('my-awesome-file.csv')

    expect(content).to eq(Base64.encode64 new_content)
  end

  it 'updates a file within a folder', :delete_repo do
    @git_data.create
    @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
    @git_data.add_file('data/my-awesome-file.csv', @file)
    @git_data.push

    @new_data = GitData.new(@client, @name, @username)

    @new_data.find
    new_content = "new,content,here\r\n1,2,3"

    @new_data.update_file('data/my-awesome-file.csv', new_content)
    @new_data.push

    tree = @client.tree(@repo_name, @new_data.base_tree, recursive: true)
    content = @client.contents(@repo_name, path: 'data/my-awesome-file.csv', ref: 'heads/gh-pages').content
    expect(tree.tree.count).to eq(3)
    expect(tree.tree.last.path).to eq('data/my-awesome-file.csv')

    expect(content).to eq(Base64.encode64 new_content)
  end

end
