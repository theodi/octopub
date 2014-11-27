xml.instruct! :xml, :version => "1.0"
xml.feed :xmlns => "http://www.w3.org/2005/Atom", "xmlns:dc" => "http://purl.org/dc/elements/1.1/" do
  xml.author do |author|
    author.name "Open Data Institute"
  end
  xml.title "Git Data Publisher - All Datasets"
  @datasets.each do |dataset|
    xml.entry do
      xml.title dataset.name
      xml.id dataset.gh_pages_url
      xml.link dataset.gh_pages_url
      xml.updated dataset.updated_at.to_datetime.rfc3339.sub(/\+00:00$/, 'Z')
    end
  end
end
