class DatasetFilesController < ApplicationController

  def index
    dataset_id = params[:dataset_id]
    @dataset = Dataset.find(dataset_id)
    @dataset_files = DatasetFile.where(dataset_id: dataset_id)
    render_403_permissions unless current_user == @dataset.user || admin_user
  end

	def show
		dataset_id = params[:dataset_file_id]
		@dataset_file = DatasetFile.find(dataset_id)
		@csv_string = FileStorageService.get_string_io(@dataset_file.storage_key).string
		@csv = CSV.parse(@csv_string, col_sep: "\t", headers: true).map(&:to_h)
	end

  def download
    dataset_file_id = params[:id]
    @dataset_file = DatasetFile.find(dataset_file_id)
    user = @dataset_file.dataset.user
    render_403_permissions unless current_user == user || admin_user

    redirect_to FileStorageService.get_temporary_download_url(@dataset_file.storage_key)
  end
end
