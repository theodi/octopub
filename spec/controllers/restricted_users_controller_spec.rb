require 'rails_helper'

describe RestrictedUsersController, type: :controller do
  render_views

  let(:admin) { create(:admin) }

  before(:each) do
    @publisher = create(:user)
  end

  it 'returns 403 if user is not logged in' do
    get :edit, params: { id: @publisher.id }
    expect(response.code).to eq("403")
  end

  describe "when logged in" do

    before(:each) do
      sign_in admin
    end

    it "shows a user's details" do
      get :edit, params: { id: @publisher.id }
      expect(CGI.unescapeHTML(response.body)).to match(/#{@publisher.name}/)
      expect(response.body).to match(/#{@publisher.email}/)
      expect(response.body).to match(/#{@publisher.api_key}/)
    end

    it "updates a user's email" do
      put :update, params: { id: @publisher.id, user: { email: 'newemail@example.com' }}
      @publisher.reload
      expect(@publisher.email).to eq 'newemail@example.com'
    end

    it "updates a user's role" do
      expect(@publisher.role).to eq 'publisher'
      put :update, params: { id: @publisher.id, user: { role: 'superuser' }}
      @publisher.reload
      expect(@publisher.role).to eq 'superuser'
    end

    it "updates a user's allocated schemas" do

      dataset_file_schema_1 = create(:dataset_file_schema)
      dataset_file_schema_2 = create(:dataset_file_schema)

      @publisher.allocated_dataset_file_schemas << dataset_file_schema_1
      @publisher.reload
      expect(@publisher.allocated_dataset_file_schemas.count).to be 1

      put :update, params: { id: @publisher.id, user: { allocated_dataset_file_schema_ids: [ dataset_file_schema_1.id, dataset_file_schema_2.id ] }}

      expect(@publisher.allocated_dataset_file_schemas.count).to be 2
      expect(@publisher.allocated_dataset_file_schemas).to include(dataset_file_schema_1, dataset_file_schema_2)
    end
  end
end
