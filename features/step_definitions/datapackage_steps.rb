Then(/^a datapackage\.json should be generated$/) do
  @datapackage = {}

  @datapackage["name"] = @name.downcase.dasherize
  @datapackage["datapackage-version"] = ""
  @datapackage["title"] = @name
  @datapackage["description"] = @description
  @datapackage["licenses"] = [{
    "url"   => @license.url,
    "title" => @license.title
  }]
  @datapackage["publishers"] = [{
    "name"   => @publisher_name,
    "web" => @publisher_url
  }]

  @datapackage["resources"] = []

  @files.each do |file|
    @datapackage["resources"] << {
      "url" => "http://#{@nickname}.github.io/#{@repo_name}/data/#{file[:filename]}",
      "name" => "#{file[:name]}",
      "mediatype" => "",
      "description" => "#{file[:description]}",
      "path" => "data/#{file[:filename]}"
    }
  end

end

Then(/^the datapackage\.json should be added to my repo$/) do
  steps %Q{
    Then a new Github repo should be created
    And my #{@dataset_count} datasets should get added to my repo
  }

  expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
    @full_name.downcase,
    "datapackage.json",
    "Adding datapackage.json",
    @datapackage.to_json,
    branch: "gh-pages"
  )
end
