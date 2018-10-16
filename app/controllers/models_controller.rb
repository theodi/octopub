class ModelsController < ApplicationController

	def index
		@models = Model.where(user: current_user)
		redirect_to :controller => 'dataset_file_schemas', :action => 'index'
	end

	def new
	end
end