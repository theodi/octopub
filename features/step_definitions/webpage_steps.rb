When(/^the index\.html should be added to my repo$/) do
  steps %Q{
    Then a new Github repo should be created
    And my #{@dataset_count} datasets should get added to my repo
  }

  expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
    @full_name,
    "index.html",
    "Adding index.html",
    an_instance_of(ActionView::OutputBuffer),
    branch: "gh-pages"
  )

end

Then(/^the assets should be added to my repo$/) do
  ['css/style.css', 'img/logo.png','img/logo_cc_80x15.png','img/rss.png'].each do |filename|
    expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
      @full_name,
      filename,
      "Adding #{filename.split("/").last}",
      an_instance_of(String),
      branch: "gh-pages"
    )
  end

  expect_any_instance_of(Octokit::Client).to receive(:create_contents).at_least(:once)
end

When(/^the page should contain the correct stuff$/) do
  webpage = Dataset.last.webpage

  expect(webpage).to match /#{@title}/
  expect(webpage).to match /#{@description}/
  expect(webpage).to match /#{@publisher_name}/
  expect(webpage).to match /#{@publisher_url}/
  expect(webpage).to match /#{@license.url}/
  expect(webpage).to match /#{Regexp.escape(@license.title)}/
  expect(webpage).to match /#{Regexp.escape(@license.url)}/

  @files.each do |file|
    expect(webpage).to match /#{file[:filename]}/
    expect(webpage).to match /#{file[:name]}/
    expect(webpage).to match /#{file[:description]}/
    expect(webpage).to match /text\/csv/
  end

  expect(webpage).to match /http:\/\/github.com\/#{@full_name}\/issues/
  expect(webpage).to match /http:\/\/github.com\/#{@full_name}\/commits\/gh_pages\.atom/

end
