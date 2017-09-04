# By default Pusher will get everything from the PUSHER_URL config, if set,
# but set cluster manually as it's value can't be retrieved (currently) from the Pusher object
if ENV['PUSHER_URL'].nil? || ENV['PUSHER_URL'] == ''
  Pusher.app_id = ENV['PUSHER_APP_ID']
  Pusher.key = ENV['PUSHER_KEY']
  Pusher.secret = ENV['PUSHER_SECRET']

end

# This sets the cluster if set as an environment variable
unless ENV['PUSHER_CLUSTER'].nil?
  Pusher.cluster = ENV['PUSHER_CLUSTER']

  # But as we can't get it later from the Pusher object, set it in rails config too
  Rails.application.config.pusher_cluster = ENV['PUSHER_CLUSTER']
end
