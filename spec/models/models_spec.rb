# == Schema Information
#
# Table name: models
#
#  id                :integer          not null, primary key
#  name              :string
#  description       :text
#  created_at        :datetime
#  updated_at        :datetime

require 'rails_helper'

describe Model do

	before(:each) do
		@user = create(:user)
	end

	it 'creates a valid model' do
		model = create(:model, user: @user)
		expect(model).to be_valid
		expect(model.name).to eq('My Awesome Model')
	end
end