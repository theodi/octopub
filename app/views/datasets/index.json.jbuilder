json.datasets do
  json.array! @datasets do |dataset|
    json.name dataset.name
    json.url dataset.gh_pages_url
  end
end
