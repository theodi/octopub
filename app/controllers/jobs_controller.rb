class JobsController < ApplicationController

  def show
    @dataset = Dataset.find_by_job_id(params[:id])
    @error = Error.find_by_job_id(params[:id])
    if @dataset
      response = {
        status: "complete",
        dataset_url: dataset_url(@dataset.id, format: :json)
      }.to_json
    elsif !@error.nil?
      response = {
        status: "error",
        errors: @error.messages
      }.to_json
    else
      response = {
        status: "running"
      }.to_json
    end

    render json: response
  end

end
