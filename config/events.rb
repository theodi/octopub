WebsocketRails::EventMap.describe do
  namespace :datasets do
    subscribe :create, 'message#create'
  end
end
