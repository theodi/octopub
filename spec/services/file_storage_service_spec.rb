require 'rails_helper'
require 'webmock/rspec'

describe FileStorageService do

  let(:filename) { 'this-is-the-filename'}

  before(:each) do
    @body = StringIO.new "woof"
    @storage_key = 'the key, the secret'
    allow(FileStorageService).to receive(:get_bucket) {
      @bucket = double(Aws::S3::Bucket)

    }
    @object = double(Aws::S3::Object)
    allow(FileStorageService).to receive(:get_object) {
      @object = double(Aws::S3::Object)
      @got_object = double(Aws::S3::Types::GetObjectOutput)
      allow(@object).to receive(:get) { @got_object }
      allow(@got_object).to receive(:body) { @body }
      allow(@object).to receive(:presigned_url) { "https://example.org/uploads/1234/#{filename}" }
      @object
    }
  end

  it "gets an object given a storage key" do
    expect(FileStorageService.get_object(@storage_key)).to be @object
  end

  it "gets string io given a storage key" do
    expect(FileStorageService.get_string_io(@storage_key)).to be @body
  end

  it "creates a unique object key" do
    filename = 'this-is-the-filename'
    expect(FileStorageService.object_key(filename)).to match "/#{filename}"
    expect(FileStorageService.object_key(filename)).to match "uploads/"
  end

  it "uploads a file" do
    expect_any_instance_of(Net::HTTP).to receive(:send_request).with(
      "PUT",
      "/uploads/1234/this-is-the-filename",
      @body,
      { "content-type" => "" })
    FileStorageService.create_and_upload_public_object(filename, @body)
  end
end
