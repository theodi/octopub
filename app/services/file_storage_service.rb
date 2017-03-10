class FileStorageService

  def self.get_object(storage_key)
    get_bucket.object(storage_key)
  end

  def self.get_string_io(storage_key)
    get_object(storage_key).get.body
  end

  def self.get_presigned_post(bucket_attributes)

  end

  def self.get_bucket
    S3_BUCKET
  end

end