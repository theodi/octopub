require 'rails_helper'

describe JekyllService, vcr: { :match_requests_on => [:host, :method] } do

  let(:user) { create(:user) }
  let(:path) { get_fixture_file('test-data.csv') }

context 'creating certificates for public datasets' do

    before(:each) do
      @user = create(:user)
      @dataset = create(:dataset, user: @user)
      @jekyll_service = JekyllService.new(@dataset)
      @certificate_url = 'http://staging.certificates.theodi.org/en/datasets/162441/certificate.json'
      allow(@dataset).to receive(:full_name) { "theodi/blockchain-and-distributed-technology-landscape-research" }
      allow(@dataset).to receive(:gh_pages_url) { "http://theodi.github.io/blockchain-and-distributed-technology-landscape-research" }
    end

    it "checks if page build is finished" do
      allow(@user).to receive(:octokit_client) do
        client = double(Octokit::Client)
        allow(client).to receive(:pages).with(@dataset.full_name) do
          OpenStruct.new(status: 'pending')
        end
        client
      end
      expect(@jekyll_service.gh_pages_building?(@dataset)).to be true
    end

    it "confirms page build is finished" do
       allow(@user).to receive(:octokit_client) do
        client = double(Octokit::Client)
        allow(client).to receive(:pages).with(@dataset.full_name) do
          OpenStruct.new(status: 'built')
        end
        client
      end
      expect(@jekyll_service.gh_pages_building?(@dataset)).to be false
    end

    it 'waits for the page build to finish' do
      user = @dataset.user
      expect(@jekyll_service).to receive(:push_to_github)
      expect(@jekyll_service).to receive(:add_file_to_repo).exactly(9).times

      allow(user).to receive(:octokit_client) do
        client = double(Octokit::Client)
        allow(client).to receive(:pages).with(@dataset.full_name).and_return {
          OpenStruct.new(status: 'pending')
        }
      end

      expect(@jekyll_service).to receive(:gh_pages_building?).with(@dataset).once.and_return(false)
      expect(@jekyll_service).to receive(:sleep).with(5)
      expect(@jekyll_service).to receive(:gh_pages_building?).with(@dataset).once.and_return(true)

      @jekyll_service.create_public_views(@dataset)
    end

    it 'creates a certificate' do
      factory = double(CertificateFactory::Certificate)

      expect(CertificateFactory::Certificate).to receive(:new).with(@dataset.gh_pages_url) {
        factory
      }

      expect(factory).to receive(:generate) {{ success: 'pending' }}
      expect(factory).to receive(:result) {{ certificate_url: @certificate_url }}
      expect(@dataset).to receive(:add_certificate_url).with(@certificate_url)

      @dataset.send(:create_certificate)
    end

    it 'adds the badge url to the repo' do
      expect(@dataset).to receive(:fetch_repo)
      expect_any_instance_of(JekyllService).to receive(:update_file_in_repo).with('_config.yml', {
        "data_source" => ".",
        "update_frequency" => @dataset.frequency,
        "certificate_url" => "http://staging.certificates.theodi.org/en/datasets/162441/certificate/badge.js"
      }.to_yaml)
      expect_any_instance_of(JekyllService).to receive(:push_to_github)

      @dataset.send(:add_certificate_url, @certificate_url)

      expect(@dataset.certificate_url).to eq('http://staging.certificates.theodi.org/en/datasets/162441/certificate')
    end
  end
end
