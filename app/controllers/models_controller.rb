class ModelsController < ApplicationController

	def index
		redirect_to :controller => 'dataset_file_schemas', :action => 'index'
	end

	def new
	end
end