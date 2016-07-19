class AddCertificateUrlToDataset < ActiveRecord::Migration
  def change
    add_column :datasets, :certificate_url, :string
  end
end
