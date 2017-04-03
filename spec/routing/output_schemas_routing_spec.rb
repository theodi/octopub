require "rails_helper"

RSpec.describe OutputSchemasController, type: :routing do
  describe "routing" do

    it "routes to #index" do
      expect(:get => "/output_schemas").to route_to("output_schemas#index")
    end

    it "routes to #new" do
      expect(:get => "/output_schemas/new").to route_to("output_schemas#new")
    end

    it "routes to #show" do
      expect(:get => "/output_schemas/1").to route_to("output_schemas#show", :id => "1")
    end

    it "routes to #edit" do
      expect(:get => "/output_schemas/1/edit").to route_to("output_schemas#edit", :id => "1")
    end

    it "routes to #create" do
      expect(:post => "/output_schemas").to route_to("output_schemas#create")
    end

    it "routes to #update via PUT" do
      expect(:put => "/output_schemas/1").to route_to("output_schemas#update", :id => "1")
    end

    it "routes to #update via PATCH" do
      expect(:patch => "/output_schemas/1").to route_to("output_schemas#update", :id => "1")
    end

    it "routes to #destroy" do
      expect(:delete => "/output_schemas/1").to route_to("output_schemas#destroy", :id => "1")
    end

  end
end
