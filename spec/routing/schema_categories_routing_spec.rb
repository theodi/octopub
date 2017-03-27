require "rails_helper"

RSpec.describe SchemaCategoriesController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/schema_categories").to route_to("schema_categories#index")
    end

    it "routes to #new" do
      expect(:get => "/schema_categories/new").to route_to("schema_categories#new")
    end

    it "routes to #edit" do
      expect(:get => "/schema_categories/1/edit").to route_to("schema_categories#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/schema_categories").to route_to("schema_categories#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/schema_categories/1").to route_to("schema_categories#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/schema_categories/1").to route_to("schema_categories#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/schema_categories/1").to route_to("schema_categories#destroy", :id => "1")
    end
  end
end
