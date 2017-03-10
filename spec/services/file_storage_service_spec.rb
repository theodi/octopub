require 'rails_helper'

describe FileStorageService do

  before(:each) do
    @body = StringIO.new "woof"
    @storage_key = 'the key, the secret'
    allow(FileStorageService).to receive(:get_bucket) {
      @bucket = double(Aws::S3::Bucket)
    }
    expect(FileStorageService).to receive(:get_object) {
      @object = double(Aws::S3::Object)
      @got_object = double(Aws::S3::Types::GetObjectOutput)
      allow(@object).to receive(:get) { @got_object }
      allow(@got_object).to receive(:body) { @body }
      @object
    }
  end

  it "gets an object given a storage key" do
    expect(FileStorageService.get_object(@storage_key)).to be @object 
  end

  it "gets string io given a storage key" do
    expect(FileStorageService.get_string_io(@storage_key)).to be @body 
  end

end