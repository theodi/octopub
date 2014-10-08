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
  @files = []

  fill_in "Dataset name", with: @name
  fill_in "Description", with: @description
  fill_in "Publisher name", with: @publisher_name
  fill_in "Publisher URL", with: @publisher_url
  select @license.title, from: "_dataset[license]"
  select @frequency, from: "_dataset[frequency]"

  @repo = "test/My-cool-dataset"
end

When(/^I specify a file$/) do
  name = 'Test Data'
  filename = 'test-data.csv'
  path = File.join(Rails.root, 'features', 'fixtures', filename)

  @files << {
    :name => name,
    :filename => filename,
    :path => path
  }

  attach_file "_files[][file]", path
end

When(/^I specify (\d+) files$/) do |num|
  @dataset_count = num.to_i
  num.to_i.times do |n|
    filename = "test-data-#{n}.csv"

    file = Tempfile.new(filename)
    file.write(SecureRandom.hex)
    file.rewind

    name = "Test Data #{n}"

    @files << {
      :name => "Test Data #{n}",
      :filename => File.basename(file.path),
      :path => file.path
    }

    all("#files input[type=text]").last.set(name)
    all("input[type=file]").last.set(file.path)
    click_link 'clone'
  end
end

Then(/^my (\d+) datasets should get added to my repo$/) do |num|
  num.to_i.times do |n|
    file = @files[n]
    expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
      @repo,
      file[:filename],
      "Adding #{file[:filename]}",
      File.open(file[:path]).read
    )
  end
end

When(/^my dataset should get added to my repo$/) do
  expect_any_instance_of(Octokit::Client).to receive(:create_contents).with(
      @repo,
      @files.first[:filename],
      "Adding #{@files.first[:filename]}",
      File.open(@files.first[:path]).read
  )
  expect_any_instance_of(Octokit::Client).to receive(:create_contents).at_least(:once)
end

When(/^I click submit$/) do
  click_button "Submit"
end

Then(/^a new Github repo should be created$/) do
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

When(/^I don't specify any files$/) do
  # nothing
end
