require 'rails_helper'

RSpec.describe "schema_categories/index", type: :view do
  before(:each) do
    assign(:schema_categories, [
      SchemaCategory.create!(name: 'woof'),
      SchemaCategory.create!(name: 'woof2')
    ])
  end

  it "renders a list of schema_categories" do
    render
  end
end
