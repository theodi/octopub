class DatasetsController < ApplicationController

  def index
    @datasets = current_user.datasets
  end

  def new
    @licenses = [
                  "cc-by",
                  "cc-by-sa",
                  "cc0",
                  "ogl-uk",
                  "odc-by",
                  "odc-pddl"
                ].map do |id|
                  license = Odlifier::License.define(id)
                  [license.title, license.id]
                end
    @dataset = Dataset.new
  end

  def create
    dataset = current_user.datasets.create(dataset_params)
    dataset.add_files(params["files"]) unless params["files"].nil?
    redirect_to datasets_path, :notice => "Dataset created sucessfully"
  end

  private

  def dataset_params
    params.require(:dataset).permit(:name, :description, :publisher_name, :publisher_url, :license, :frequency)
  end

end
