namespace :links do

  def eval_response_code?(url_string)
    url = URI.parse(url_string)
    req = Net::HTTP.new(url.host, url.port)
    req.use_ssl = true if url.scheme == 'https' # TY gentle knight https://gist.github.com/murdoch/1168520#gistcomment-1238015
    res = req.request_head(url.path)
    res.code.to_i == 200
  end

  desc "flag datasets that have broken links"
  task broken: :environment do
    Dataset.all.each do |dataset|
      # check if dataset is live
      if dataset.url.nil?
        puts "#{dataset.name} lacks URL: #{dataset.url}"
        Rails.logger.warn "#{dataset.name} lacks URL"
      end

      if eval_response_code?(dataset.url)
        puts "#{dataset.name} has URL live at #{dataset.url}"
        Rails.logger.info "#{dataset.name} live at #{dataset.url}"
        # dataset.update_column(:url_found, true)
        # puts dataset.url_found
        # dataset.url_found = true
      else
        puts "#{dataset.name} lacks URL : #{dataset.url}"
        Rails.logger.warn "#{dataset.name} no longer has a live URL : #{dataset.url}"
        dataset.update_column(:url_deprecated_at, DateTime.now())
        # binding.pry
        # dataset.deprecated_resource
        # puts dataset.url_found
        # dataset.url_found = false
      end
    end
  end
end