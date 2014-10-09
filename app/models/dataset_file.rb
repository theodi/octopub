class DatasetFile < ActiveRecord::Base

  belongs_to :dataset

  after_create :add_to_github

  attr_accessor :tempfile

  private

    def add_to_github
      dataset.create_contents(filename, tempfile.read, "data")
    end

end
