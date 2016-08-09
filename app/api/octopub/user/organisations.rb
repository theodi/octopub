module Octopub
  module User
    class Organisations < Grape::API
      desc 'Lists all Github organisations for the authenticated user.', is_array: true, http_codes: [
        { code: 200, message: 'OK', model: Octopub::Entities::Organisations }
      ]
      get '/user/organisations' do
        authenticate!

        Octopub::Entities::Organisations.represent(current_user.organizations)
      end
    end
  end
end
