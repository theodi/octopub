class AddCertificateUrlToDataset < ActiveRecord::Migration[4.2]
  def change
    add_column :datasets, :certificate_url, :string
  end
end
