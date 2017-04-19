namespace :links do
  desc "flag datasets that have broken links"
  task broken: :environment do
    Dataset.all.each do |dataset|
      # check if dataset is live
      if dataset.url.nil?
        Rails.logger.warn "#{dataset.name} no longer has a live URL"
        # dataset.url_found = false
      else
        uri = URI(dataset.url)
        req = Net::HTTP.new uri.host
        res= req.request_head uri.path
        if res.to_i == 404
          Rails.logger.warn "#{dataset.name} no longer has a live URL"
          dataset.update_column(:url_found, false)
          # dataset.url_found = false
        else
          Rails.logger.warn "#{dataset.name} live at #{dataset.url}"
          # dataset.url_found = true
        end
      end
    end
  end
end