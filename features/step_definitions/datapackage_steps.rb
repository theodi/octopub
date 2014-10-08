Then(/^a datapackage\.json should be generated$/) do
  @datapackage = {}

  @datapackage["name"] = @name
  @datapackage["datapackage-version"] = ""
  @datapackage["title"] = @name
  @datapackage["description"] = @description
  @datapackage["licenses"] = [{
    "url"   => @license.url,
    "title" => @license.title
  }]
  @datapackage["publishers"] = [{
    "url"   => @publisher_name,
    "title" => @publisher_url
  }]

  @datapackage["resources"] = []

  @files.each do |file|
    @datapackage["resources"] << {
      "url" => "http://github.com/#{@repo}/data/#{file[:filename]}",
      "name" => "#{file[:filename]}",
      "mediatype" => "",
      "description" => "#{file[:name]}"
    }
  end

end

Then(/^the datapackage\.json should be added to my repo$/) do
  steps %Q{
    Then a new Github repo should be created
    And my #{@dataset_count} datasets should get added to my repo
  }

  expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
    @repo,
    "datapackage.json",
    "Adding datapackage.json",
    @datapackage.to_json
  )
end
