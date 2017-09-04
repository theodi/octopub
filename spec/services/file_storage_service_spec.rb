require 'rails_helper'
require 'webmock/rspec'

describe FileStorageService do

  let(:filename) { 'this-is-the-filename'}

  before(:each) do
    @body = StringIO.new "woof"
    @storage_key = 'the key, the secret'
    @bucket = double(Aws::S3::Bucket)
    @object = double(Aws::S3::Object)
    @got_object = double(Aws::S3::Types::GetObjectOutput)
    @presigned_url = "https://example.org/uploads/1234/#{filename}"

    allow(FileStorageService).to receive(:get_bucket) { @bucket }
    allow(FileStorageService).to receive(:get_object) {
      allow(@object).to receive(:get) { @got_object }
      allow(@got_object).to receive(:body) { @body }
      allow(@object).to receive(:presigned_url) { @presigned_url }
      @object
    }
  end

  it "gets an object given a storage key" do
    expect(FileStorageService.get_object(@storage_key)).to be @object
  end

  it "gets a temporary url for an object given a storage key" do
    expect(@object).to receive(:presigned_url).with(:get, { expires_in: 1.minute })
    FileStorageService.get_temporary_download_url(@storage_key)
  end

  it "gets string io given a storage key" do
    expect(FileStorageService.get_string_io(@storage_key)).to be @body
  end

  it "creates a unique object key" do
    filename = 'this-is-the-filename'
    expect(FileStorageService.object_key(filename)).to match "/#{filename}"
    expect(FileStorageService.object_key(filename)).to match "uploads/"
  end

  it "creates a unique object key with a predefined uuid" do
    filename = 'this-is-the-filename'
    uuid = SecureRandom.uuid
    expect(FileStorageService.object_key(filename, uuid)).to match "uploads/#{uuid}/#{filename}"
  end

  it "uploads a public file" do
    expect_any_instance_of(Net::HTTP).to receive(:send_request).with(
      "PUT",
      "/uploads/1234/this-is-the-filename",
      @body,
      { "content-type" => "" })
    FileStorageService.create_and_upload_public_object(filename, @body)
  end

  it "uploads a private file" do
    allow(FileStorageService).to receive(:get_object) {
      @object = double(Aws::S3::Object)
      @got_object = double(Aws::S3::Types::GetObjectOutput)
      expect(@object).to receive(:put) { @body }
      expect(@object).to_not receive(:presigned_url) { @presigned_url }
      @object
    }
    object = FileStorageService.create_and_upload_private_object(filename, @body)
    expect(object).to be @object
  end

  it "gets an object from the bucket" do
    @storage_key = 'the key, the secret'
    @bucket = double(Aws::S3::Bucket)
    expect(FileStorageService).to receive(:get_bucket) { @bucket }
    expect(@bucket).to receive(:object).with(@storage_key)
    expect(FileStorageService).to receive(:get_object).and_call_original
    FileStorageService.get_object(@storage_key)
  end

  it "makes an object public" do
    @storage_key = 'the key, the secret'
    acl = double(Aws::S3::ObjectAcl)
    expect(FileStorageService).to receive(:get_object).with(@storage_key) { @got_object }
    expect(@got_object).to receive(:acl) { acl }
    expect(acl).to receive(:put).with({ acl: "public-read" })
    FileStorageService.make_object_public(@storage_key)
  end

  it "makes an object public from url" do
    storage_key = 'uploads/5678/the-key-the-secret.csv'
    url = "https://example.org/#{storage_key}"

    expect(FileStorageService).to receive(:make_object_public).with(storage_key)
    FileStorageService.make_object_public_from_url(url)
  end

  it "returns public bucket attributes" do
    uuid = SecureRandom.uuid
    key = "uploads/#{uuid}/${filename}"

    bucket_attributes = FileStorageService.bucket_attributes(uuid)
    expect(bucket_attributes).to be_a(Hash)
    expect(bucket_attributes[:acl]).to eq 'public-read'
    expect(bucket_attributes[:success_action_status]).to eq '201'
    expect(bucket_attributes[:key]).to eq key
  end

  it "returns private bucket attributes" do
    uuid = SecureRandom.uuid
    key = "uploads/#{uuid}/${filename}"

    bucket_attributes = FileStorageService.private_bucket_attributes(uuid)
    expect(bucket_attributes).to be_a(Hash)
    expect(bucket_attributes.key?(:acl)).to be false
    expect(bucket_attributes[:success_action_status]).to eq '201'
    expect(bucket_attributes[:key]).to eq key
  end
end
