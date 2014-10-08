When(/^I go to the add new dataset page$/) do
  visit new_dataset_path
end

When(/^I add my dataset details$/) do
  @name = "My cool dataset"
  @description = "This is a description"
  @publisher_name = "Cool inc"
  @publisher_url = "http://example.com"
  @license = Odlifier::License.define("ogl-uk")
  @frequency = "Monthly"

  fill_in "Dataset name", with: @name
  fill_in "Description", with: @description
  fill_in "Publisher name", with: @publisher_name
  fill_in "Publisher URL", with: @publisher_url
  select @license.title, from: "_dataset[license]"
  select @frequency, from: "_dataset[frequency]"
end

When(/^I specify a file$/) do
  @filename = 'test-data.csv'
  attach_file "_files[][file]", File.join(Rails.root, 'features', 'fixtures', @filename)
end

When(/^I specify (\d+) files$/) do |num|
  num.to_i.times do |n|
    filename = "test-data-#{n}.csv"
    file = Tempfile.new(filename)
    file.write(SecureRandom.hex)
    file.rewind
    instance_variable_set("@path#{n}", file.path)
    all("input[type=file]").last.set(file.path)
    click_link 'clone'
  end
end

Then(/^my (\d+) datasets should get added to my repo$/) do |num|
  num.to_i.times do |n|
    path = instance_variable_get("@path#{n}")
    filename = File.basename(path)
    expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
      @repo,
      filename,
      "Adding #{filename}",
      File.open(path).read
    )
  end
end

When(/^my dataset should get added to my repo$/) do
  expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
      @repo,
      @filename,
      "Adding #{@filename}",
      File.open(File.join(Rails.root, 'features', 'fixtures', @filename)).read
  )
end

When(/^I click submit$/) do
  click_button "Submit"
end

Then(/^a new Github repo should be created$/) do
  @repo = "test/My-cool-dataset"
  @url = "https://github.com/#{@repo}"
  expect_any_instance_of(Octokit::Client).to receive(:create_repository).with(@name) {
     { html_url: @url, full_name: @repo }
  }
end

Then(/^my repo should be listed in the datasets index$/) do
  expect(page.html).to include("<a href=\"#{@url}\">#{@name}</a>")
end

When(/^the repo details should be stored in the database$/) do
  dataset = Dataset.last

  expect(dataset.name).to eql(@name)
  expect(dataset.description).to eql(@description)
  expect(dataset.url).to eql(@url)
  expect(dataset.repo).to eql(@repo)
  expect(dataset.publisher_name).to eql(@publisher_name)
  expect(dataset.publisher_url).to eql(@publisher_url)
  expect(dataset.license).to eql(@license.id)
  expect(dataset.frequency).to eql(@frequency)
end

When(/^I should see "(.*?)"$/) do |message|
  expect(page).to have_content message
end
