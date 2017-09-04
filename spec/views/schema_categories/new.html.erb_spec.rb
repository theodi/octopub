require 'rails_helper'

RSpec.describe "schema_categories/new", type: :view do
  before(:each) do
    assign(:schema_category, SchemaCategory.new())
  end

  it "renders new schema_category form" do
    render

    assert_select "form[action=?][method=?]", schema_categories_path, "post" do
    end
  end
end
