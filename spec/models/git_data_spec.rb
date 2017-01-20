require 'spec_helper'

describe GitData, :vcr do

  before(:all) do
    @client = Octokit::Client.new :access_token => ENV['GITHUB_TOKEN']
    @name = 'My Awesome Repo'
    @username = ENV['GITHUB_USER']
  end

  before(:each) do
    @repo_name = "#{ENV['GITHUB_USER']}/my-awesome-repo"
  end

  after(:each) do
    @client.delete_repository(@repo_name)
  end

  context '#create'  do
    context 'with a user' do
      before(:each) do
        @repo = GitData.create(@username, @name, client: @client)
      end

      it 'creates a repo' do
        expect(@client.repository?(@repo_name)).to eq(true)
      end

      it 'sets gh-pages as the default branch' do
        expect(@client.repository(@repo_name).default_branch).to eq('gh-pages')
      end

      it 'sets the relevant instance variables' do
        expect(@repo.html_url).to eq("https://github.com/#{@username}/my-awesome-repo")
        expect(@repo.full_name).to eq("#{@username}/my-awesome-repo")
      end
    end

    context 'with an organization' do
      before(:each) do
        @repo = GitData.create('octopub-data', @name, client: @client)
        @repo_name = 'octopub-data/my-awesome-repo'
      end

      it 'creates a repo' do
        expect(@client.repository?(@repo_name)).to eq(true)
        expect(@client.repository(@repo_name).owner[:login]).to eq('octopub-data')
      end

      it 'sets the relevant instance variables' do
        expect(@repo.html_url).to eq('https://github.com/octopub-data/my-awesome-repo')
        expect(@repo.full_name).to eq('octopub-data/my-awesome-repo')
      end
    end

    context 'creating private repos' do
      it 'works if private repos are available' do
        # @username should have private repos available if running this test
        # without a cassette
        @repo = GitData.create(@username, @name, client: @client, private: true)
        expect(@client.repository(@repo_name).private).to eq(true)
      end

      it 'returns nil if private repos are unavailable' do
        # theodi doesn't have private repos available
        @repo = GitData.create('theodi', @name, client: @client, private: true)
        expect(@repo).to be_nil
      end
    end
    
    context 'case insensitive' do
      it 'creates a repo with the user' do
        GitData.create(@username.upcase, @name, client: @client)

        expect(@client.repository?(@repo_name)).to eq(true)
        expect(@client.repository(@repo_name).owner[:login]).to eq(@username)
      end
    end
  end

  context '#find'  do
    context 'with a user' do
      before(:each) do
        GitData.create(@username, @name, client: @client)
        @repo = GitData.find(@username, @name, client: @client)
      end

      it 'finds the repo' do
        expect(@repo.full_name).to eq("#{@username}/my-awesome-repo")
        expect(@repo.html_url).to eq("https://github.com/#{@username}/my-awesome-repo")
      end

      it 'builds a base tree' do
        expect(@repo.instance_variable_get(:@tree).count).to eq(1)
      end
    end

    context 'with an organisation' do
      before(:each) do
        GitData.create('octopub-data', @name, client: @client)
        @repo = GitData.find('octopub-data', @name, client: @client)
      end

      it 'finds the repo' do
        expect(@repo.full_name).to eq('octopub-data/my-awesome-repo')
        expect(@repo.html_url).to eq('https://github.com/octopub-data/my-awesome-repo')
      end
    end
  end

  context '#add_file'  do
    before(:each) do
      @repo = GitData.create(@username, @name, client: @client)
      @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
    end

    it 'creates a sha for a blob' do
      expect(@repo.send(:blob_sha, @file)).to eq('c46d38c374cd81824aeb74476abc53293db77b08')
    end

    it 'appends to a tree' do
      @repo.instance_variable_set(:"@tree", nil)
      @repo.add_file('my-awesome-file.csv', @file)

      expect(@repo.send(:tree)).to eq([
        {
          "path" => 'my-awesome-file.csv',
          "mode" => "100644",
          "type" => "blob",
          "sha" => 'c46d38c374cd81824aeb74476abc53293db77b08'
        }
      ])
    end

    it 'appends multiple files to a tree' do
      @repo.instance_variable_set(:"@tree", nil)
      @repo.add_file('my-awesome-file.csv', @file)
      @repo.add_file('my-other-awesome-file.csv', @file)

      expect(@repo.send(:tree)).to eq([
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

  context '#update_file'  do
    before(:each) do
      repo = GitData.create(@username, @name, client: @client)
      repo.add_file('my-awesome-file.csv', "old content")
      repo.save

      @repo = GitData.find(@username, @name, client: @client)
      @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
    end

    it 'updates a file' do
      new_content = "new,content,here\r\n1,2,3"
      @repo.update_file('my-awesome-file.csv', new_content)

      expected = Digest::SHA1.hexdigest "blob #{new_content.length}\0#{new_content}"

      expect(@repo.send(:tree).last).to eq({
        "path" => 'my-awesome-file.csv',
        "mode" => "100644",
        "type" => "blob",
        "sha" => expected
      })
    end
  end

  context '#delete_file'  do
    before(:each) do
      repo = GitData.create(@username, @name, client: @client)
      repo.add_file('my-awesome-file.csv', "old content")
      repo.add_file('my-other-awesome-file.csv', "old content")
      repo.save

      @repo = GitData.find(@username, @name, client: @client)
      @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
    end

    it 'deletes a file' do
      @repo.delete_file('my-other-awesome-file.csv')
      tree = @repo.send(:tree)

      expect(tree.count).to eq(2)
      expect(tree.select { |t| t['path'] == 'data/my-other-awesome-file.csv' }.count).to eq(0)
    end

  end

  context '#get_file'  do

    it 'gets a file' do
      repo = GitData.create(@username, @name, client: @client)
      repo.add_file('my-awesome-file.csv', "Well hi there!")
      repo.save

      @repo = GitData.find(@username, @name, client: @client)

      expect(@repo.get_file('my-awesome-file.csv')).to eq("Well hi there!")
    end

    it 'gets a file in a folder' do
      repo = GitData.create(@username, @name, client: @client)
      repo.add_file('_data/my-awesome-file.csv', "I'm in a folder!")
      repo.save

      @repo = GitData.find(@username, @name, client: @client)

      expect(@repo.get_file('_data/my-awesome-file.csv')).to eq("I'm in a folder!")
    end

  end

  context '#save'  do

    before(:each) do
      @repo = GitData.create(@username, @name, client: @client)
      @file = File.read(File.join(File.dirname(__FILE__), '..', 'fixtures', 'test-data.csv'))
    end

    it 'adds a single file' do
      @repo.add_file('my-awesome-file.csv', @file)
      @repo.save

      tree = GitData.find(@username, @name, client: @client).send(:tree)

      expect(tree.count).to eq(2)
      expect(tree.last['path']).to eq('my-awesome-file.csv')
    end

    it 'adds multiple files' do
      @repo.add_file('my-awesome-file.csv', @file)
      @repo.add_file('my-other-awesome-file.csv', @file)
      @repo.save

      tree = GitData.find(@username, @name, client: @client).send(:tree)

      expect(tree.count).to eq(3)
      expect(tree[1]['path']).to eq('my-awesome-file.csv')
      expect(tree[2]['path']).to eq('my-other-awesome-file.csv')
    end

    it 'adds a file within a folder' do
      @repo.add_file('data/my-awesome-file.csv', @file)
      @repo.save

      tree = GitData.find(@username, @name, client: @client).send(:tree)

      expect(tree.count).to eq(2)
      expect(tree.last['path']).to eq('data/my-awesome-file.csv')
    end

    it 'adds muliple files within a folder' do
      @repo.add_file('data/my-awesome-file.csv', @file)
      @repo.add_file('data/my-other-awesome-file.csv', @file)
      @repo.save

      tree = GitData.find(@username, @name, client: @client).send(:tree)

      expect(tree.count).to eq(3)
      expect(tree[1]['path']).to eq('data/my-awesome-file.csv')
      expect(tree[2]['path']).to eq('data/my-other-awesome-file.csv')
    end

    it 'updates a file' do
      @repo.add_file('my-awesome-file.csv', @file)
      @repo.save

      new_content = "new,content,here\r\n1,2,3"

      repo = GitData.find(@username, @name, client: @client)
      repo.update_file('my-awesome-file.csv', new_content)
      repo.save

      tree = GitData.find(@username, @name, client: @client).send(:tree)
      content = @client.contents(@repo_name, path: 'my-awesome-file.csv', ref: 'heads/gh-pages').content

      expect(tree.count).to eq(2)
      expect(tree.last['path']).to eq('my-awesome-file.csv')
      expect(content).to eq(Base64.encode64 new_content)
    end

    it 'deletes a file' do
      @repo.add_file('my-awesome-file.csv', @file)
      @repo.add_file('my-other-awesome-file.csv', @file)
      @repo.save

      repo = GitData.find(@username, @name, client: @client)
      repo.delete_file('my-other-awesome-file.csv')
      repo.save

      tree = GitData.find(@username, @name, client: @client).send(:tree)
      expect(tree.count).to eq(2)
      expect(tree.last['path']).to eq('my-awesome-file.csv')
    end
  end

  context '#delete' do
    it 'deletes a repo' do
      @repo = GitData.create(@username, @name, client: @client)
      expect(@client.repository?(@repo_name)).to eq(true)

      @repo.delete

      expect(@client.repository?(@repo_name)).to eq(false)
    end
  end

end
