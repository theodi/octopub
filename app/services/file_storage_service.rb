class FileStorageService

  def self.get_object(storage_key)
    get_bucket.object(storage_key)
  end

  def self.get_temporary_download_url(storage_key)
    get_object(storage_key).presigned_url(:get, expires_in: 1.minutes)
  end

  def self.make_object_public(storage_key)
    get_object(storage_key).acl.put({ acl: "public-read" })
  end

  def self.make_object_public_from_url(url)
    storage_key = get_storage_key_from_public_url(url)
    make_object_public(storage_key)
  end

  def self.get_string_io(storage_key)
    get_object(storage_key).get.body
  end

  def self.presigned_post(uuid = SecureRandom.uuid)
    get_bucket.presigned_post(bucket_attributes(uuid))
  end

  def self.private_presigned_post(uuid = SecureRandom.uuid)
    get_bucket.presigned_post(private_bucket_attributes(uuid))
  end

  def self.get_bucket
    S3_BUCKET
  end

  def self.create_and_upload_public_object(filename, body)
    key = object_key(filename)
    push_public_object(key, body)
  end

  def self.push_public_object(storage_key, body)
    obj = get_object(storage_key)
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
    obj = get_object(key)
    obj.put(body: body)
    obj
  end

  def self.object_key(filename, uuid = SecureRandom.uuid)
    "uploads/#{uuid}/#{filename}"
  end

  def self.get_storage_key_from_public_url(public_url)
    return if public_url.nil?
    URI(public_url).path.gsub(/^\//, '')
  end

  def self.bucket_attributes(uuid)
    { key: "uploads/#{uuid}/${filename}", success_action_status: '201', acl: 'public-read' }
  end

  def self.private_bucket_attributes(uuid)
    { key: "uploads/#{uuid}/${filename}", success_action_status: '201' }
  end

end
