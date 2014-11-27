When(/^the index\.html should be added to my repo$/) do
  steps %Q{
    Then a new Github repo should be created
    And my #{@dataset_count} datasets should get added to my repo
  }

  expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
    @full_name,
    "index.html",
    "Adding index.html",
    File.open(File.join(Rails.root, "extra", "html", "index.html")).read,
    branch: "gh-pages"
  )

end

Then(/^the assets should be added to my repo$/) do
  ['css/style.css', '_layouts/default.html'].each do |filename|
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
