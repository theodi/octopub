require 'rails_helper'

RSpec.describe "schema_categories/show", type: :view do
  before(:each) do
    @schema_category = assign(:schema_category, SchemaCategory.create!())
  end

  it "renders attributes in <p>" do
    render
  end
end
