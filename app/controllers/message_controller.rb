class MessageController < WebsocketRails::BaseController
  def create
    params = Rack::Utils.parse_nested_query message
    user = User.find(params["user"])
    Dataset.delay.create_dataset(params["dataset"], params["files"], user, perform_async: true)
  end
end
