unless Rails.env.test?

  Aws.config.update({
  region: 'eu-west-1',
  credentials: Aws::Credentials.new(ENV['AWS_ACCESS_KEY_ID'], ENV['AWS_SECRET_ACCESS_KEY']),
  })

  S3_BUCKET = Aws::S3::Resource.new.bucket(ENV['S3_BUCKET'])

else

  # In test mode we don't want any AWS stuff going to the real thing
  Aws.config.update({
    region: 'eu-west-1',
    credentials: Aws::Credentials.new('1234', '5678'),
    stub_responses: true
  })

  s3 = Aws::S3::Client.new
  S3_BUCKET = Aws::S3::Resource.new.bucket('test-bucket')
end
