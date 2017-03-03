# == Schema Information

require 'rails_helper'

describe DatasetFileSchema do

  before(:each) do
    @user = create(:user)
    @good_schema_url = url_with_stubbed_get_for_fixture_file('schemas/good-schema.json')
    @bad_schema_url = url_with_stubbed_get_for_fixture_file('schemas/bad-schema.json')
    @empty_schema_url = url_with_stubbed_get_for_fixture_file('schemas/empty-schema.json')
    @schema_with_pk_no_fields_url = url_with_stubbed_get_for_fixture_file('schemas/invalid-schema-pk-no-fields.json')

    @dataset_file_schema_with_url_in_repo = build(:dataset_file_schema, url_in_repo: @good_schema_url, user: @user)
    @dataset_file_schema_with_bad_schema_url_in_repo = build(:dataset_file_schema, url_in_repo: @bad_schema_url)
    @dataset_file_schema_with_empty_schema_url_in_repo = build(:dataset_file_schema, url_in_repo: @empty_schema_url)
    @dataset_file_schema_with_pk_no_fields = build(:dataset_file_schema, url_in_repo: @schema_with_pk_no_fields_url)

  end

  it "returns owner's name" do
    expect(@dataset_file_schema_with_url_in_repo.owner_name).to eq @user.name
  end

  context "has at least one url" do
    it "returns a url if set in S3" do
      dataset_file_schema = build(:dataset_file_schema, url_in_s3: @good_schema_url)
      expect(dataset_file_schema.url).not_to be_empty
    end
    it "returns a url if set in repo" do
      expect(@dataset_file_schema_with_url_in_repo.url).not_to be_empty
    end

    it "prefers repo url if both set" do
      @dataset_file_schema_with_url_in_repo.url_in_s3 = "wah"
      expect(@dataset_file_schema_with_url_in_repo.url).to eq @good_schema_url
    end
  end

  context "returns a parsed url" do
    it "for a good schema" do
      parsed_schema = @dataset_file_schema_with_url_in_repo.parsed_schema
      expect(parsed_schema).to be_instance_of Csvlint::Schema
    end

    it "for a bad schema" do
      parsed_schema = @dataset_file_schema_with_bad_schema_url_in_repo.parsed_schema
      expect(parsed_schema).to be_instance_of Csvlint::Schema
    end
  end

  context "returns validity " do
    it "as invalid for a bad schema" do
      parsed_schema = @dataset_file_schema_with_bad_schema_url_in_repo.parsed_schema
      expect(@dataset_file_schema_with_bad_schema_url_in_repo.is_schema_valid?).to be false
    end

    it "as valid for a good schema" do
      parsed_schema = @dataset_file_schema_with_url_in_repo.parsed_schema
      expect(@dataset_file_schema_with_url_in_repo.is_schema_valid?).to be true
    end

    it "returns array of errors if invalid" do
      expect(@dataset_file_schema_with_bad_schema_url_in_repo.is_valid?).to eq ['is invalid']
    end

    it "returns thing if valid" do
      expect(@dataset_file_schema_with_url_in_repo.is_valid?).to be_nil
    end
  end

  context "returns new style validity " do
    it "as invalid for a bad schema" do
      expect(@dataset_file_schema_with_bad_schema_url_in_repo.new_is_schema_valid?).to be false
    end

    it "as invalid for an empty schema" do
      expect(@dataset_file_schema_with_empty_schema_url_in_repo.new_is_schema_valid?).to be false
    end

    it "as valid for a good schema" do
      expect(@dataset_file_schema_with_url_in_repo.new_is_schema_valid?).to be true
    end

    it "returns array of errors if invalid" do
      expect(@dataset_file_schema_with_pk_no_fields.new_is_schema_valid?).to be false
      expect(@dataset_file_schema_with_pk_no_fields.new_parsed_schema.messages.count).to eq 3
    end

    it "returns thing if valid" do
      expect(@dataset_file_schema_with_url_in_repo.is_valid?).to be_nil
    end
  end

  it "nullifies associated foreign keys when deleted" do

    @dataset_file_schema_with_url_in_repo.save
    dataset_file_schema_id = @dataset_file_schema_with_url_in_repo.id
    ap @dataset_file_schema_with_url_in_repo

    file_path = get_fixture_file('valid-schema.csv')
    dataset_file_1 = create(:dataset_file,
      dataset_file_schema: @dataset_file_schema_with_url_in_repo,
      file: Rack::Test::UploadedFile.new(file_path, "text/csv")
    )
    dataset_file_2 = create(:dataset_file)
    expect(dataset_file_1.dataset_file_schema).to eq @dataset_file_schema_with_url_in_repo
    expect(dataset_file_2.dataset_file_schema).to be nil

    @dataset_file_schema_with_url_in_repo.delete
    expect { DatasetFileSchema.find(dataset_file_schema_id) }.to raise_error ActiveRecord::RecordNotFound

    dataset_file_1.reload
    expect(dataset_file_1.dataset_file_schema).to be nil
    expect(dataset_file_2.dataset_file_schema).to be nil
  end
end
