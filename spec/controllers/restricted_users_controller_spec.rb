require 'rails_helper'

describe RestrictedUsersController, type: :controller do
  include_context 'user and organisations'
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

    it "sets a user to restricted" do
      expect(@publisher.restricted).to eq false
      put :update, params: { id: @publisher.id, user: { restricted: true }}
      @publisher.reload
      expect(@publisher.restricted).to eq true
    end

    context "updates a user's allocated schemas" do

      let(:dataset_file_schema_1) { create(:dataset_file_schema) }
      let(:dataset_file_schema_2) { create(:dataset_file_schema) }

      it "individually" do
        @publisher.allocated_dataset_file_schemas << dataset_file_schema_1
        @publisher.reload
        expect(@publisher.allocated_dataset_file_schemas.count).to be 1

        put :update, params: { id: @publisher.id, user: { allocated_dataset_file_schema_ids: [ dataset_file_schema_1.id, dataset_file_schema_2.id ] }}

        expect(@publisher.allocated_dataset_file_schemas.count).to be 2
        expect(@publisher.allocated_dataset_file_schemas).to include(dataset_file_schema_1, dataset_file_schema_2)
      end

      it "by category" do
        schema_category = SchemaCategory.create(name: 'cat1', dataset_file_schemas: [ dataset_file_schema_1, dataset_file_schema_2])
        expect(schema_category.dataset_file_schemas.count).to be 2
        expect(@publisher.allocated_dataset_file_schemas.count).to be 0

        put :update, params: {
          id: @publisher.id,
          user: {
            schema_category_ids: [ schema_category.id ]
          }
        }

        expect(@publisher.allocated_dataset_file_schemas.count).to be 2
        expect(@publisher.allocated_dataset_file_schemas).to include(dataset_file_schema_1, dataset_file_schema_2)
      end

      it "by category and separately" do
        schema_category = SchemaCategory.create(name: 'cat1', dataset_file_schemas: [ dataset_file_schema_1])
        expect(schema_category.dataset_file_schemas.count).to be 1
        expect(@publisher.allocated_dataset_file_schemas.count).to be 0

        put :update, params: {
          id: @publisher.id,
          user: {
            allocated_dataset_file_schema_ids: [ dataset_file_schema_2.id ],
            schema_category_ids: [ schema_category.id ]
          }
        }

        expect(@publisher.allocated_dataset_file_schemas.count).to be 2
        expect(@publisher.allocated_dataset_file_schemas).to include(dataset_file_schema_1, dataset_file_schema_2)
      end

      it "by category and separately without duplicates" do
        schema_category = SchemaCategory.create(name: 'cat1', dataset_file_schemas: [ dataset_file_schema_1])
        expect(schema_category.dataset_file_schemas.count).to be 1
        expect(@publisher.allocated_dataset_file_schemas.count).to be 0

        put :update, params: {
          id: @publisher.id,
          user: {
            allocated_dataset_file_schema_ids: [ dataset_file_schema_1.id ],
            schema_category_ids: [ schema_category.id ]
          }
        }

        expect(@publisher.allocated_dataset_file_schemas.count).to be 1
        expect(@publisher.allocated_dataset_file_schemas).to eq [ dataset_file_schema_1 ]
      end
    end
  end
end
