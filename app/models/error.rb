# == Schema Information
#
# Table name: errors
#
#  id       :integer          not null, primary key
#  job_id   :string(255)      not null
#  messages :json
#

class Error < ActiveRecord::Base
end
