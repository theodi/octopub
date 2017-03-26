require 'rails_helper'

RSpec.describe "schema_categories/edit", type: :view do
  before(:each) do
    @schema_category = assign(:schema_category, SchemaCategory.create!())
  end

  it "renders the edit schema_category form" do
    render

    assert_select "form[action=?][method=?]", schema_category_path(@schema_category), "post" do
    end
  end
end
