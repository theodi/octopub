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

  def self.create_and_upload_public_object(filename, body)
    key = object_key(filename)
    obj = get_bucket.object(key)
    url = URI.parse(obj.presigned_url(:put, acl: 'public-read'))

    Net::HTTP.start(url.host) do |http|
      http.send_request("PUT", url.request_uri, body, {
        # This is required, or Net::HTTP will add a default unsigned content-type.
        "content-type" => "",
      })
    end
    obj
  end

  def self.create_and_upload_private_object(filename, body)
    key = object_key(filename)
    obj = S3_BUCKET.object(key)
    obj.put(body: body)
    obj
  end

  def self.object_key(filename)
    "uploads/#{SecureRandom.uuid}/#{filename}"
  end

end