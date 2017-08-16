require 'rails_helper'

describe 'datasets/_dataset.html.erb' do

  before(:each) do
    @user = create(:user)
    @dataset = create(:dataset, name: "My Dataset", repo: "my-repo", user: @user)
    allow_any_instance_of(DatasetFile).to receive(:check_schema)
    @dataset_with_schema = create(:dataset, name: "My Dataset", repo: "my-repo", user: @user,
        dataset_files: [
          create(:dataset_file, dataset_file_schema: create(:dataset_file_schema))
        ])
    allow_any_instance_of(Dataset).to receive(:owner_avatar) {
      "http://example.org/avatar.png"
    }
    @restricted_dataset = create(:dataset, name: "My Dataset", repo: "my-repo", user: @user, publishing_method: :github_private)
  end

  it 'displays a single dataset' do
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
    page = Nokogiri::HTML(rendered)
    expect(page.css('tr')[0].css('td')[0].inner_text).to match(/#{@dataset.repo_owner}/)
    expect(page.css('tr')[0].css('td')[1].inner_text).to match(/My Dataset/)
    expect(page.css('tr')[0].css('td')[2].inner_text).to eq ""
  end

  it 'displays a single dataset with schemas' do
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset_with_schema}
    page = Nokogiri::HTML(rendered)

    expect(page.css('tr')[0].css('td')[0].inner_text).to have_content(@dataset.repo_owner)
    expect(page.css('tr')[0].css('td')[1].inner_text).to match(/#{@dataset.name}/)
    expect(page.css('tr')[0].css('td')[2].inner_text).to match(/Yes/)
  end

  def expect_columns(page)
    expect(page.css('tr')[0].css('td').count).to eq(7)
  end

  it 'displays the edit link' do
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
    page = Nokogiri::HTML(rendered)
    expect_columns(page)
    expect(page.css('tr')[0].css('td')[6].inner_text).to match(/Edit/)
    expect(page.css('tr')[0].css('td')[6].inner_text).to match(/Delete/)
  end

  it 'displays access icon' do
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
    page = Nokogiri::HTML(rendered)
    expect_columns(page)
    expect(page.css('tr:first-child > td:nth-child(2)')).to have_css('i.fa.fa-globe');
    expect(page.css('tr:first-child > td:nth-child(2)')).to have_css('i[title="public"]');
  end

  it 'displays private icon' do
    render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @restricted_dataset}
    page = Nokogiri::HTML(rendered)
    expect_columns(page)

    expect(page.css('tr:first-child > td:nth-child(2)')).to have_css('i.fa.fa-lock');
    expect(page.css('tr:first-child > td:nth-child(2)')).to have_css('i[title="private"]');
  end

  context 'deprecated dataset URLs' do

    before do
      @deprecated_date = Timecop.freeze(Date.today - 7)
      @dataset.update_column(:url, "http://www.deadurl.com/example.csv")
      @dataset.update_column(:url_deprecated_at, @deprecated_date)
    end

    after :all do
      Timecop.return
    end

    it 'displays warning icon for URL inaccessible dataset' do
      render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
      page = Nokogiri::HTML(rendered)
      expect(page.css('tr:first-child > td:nth-child(2)')).to have_css('i.fa.fa-exclamation-triangle');
    end

    it 'displays deprecation date when in the dashboard' do
      render :partial => 'datasets/dataset.html.erb', :locals => {:dataset => @dataset}
      page = Nokogiri::HTML(rendered)
      expect_columns(page)
      expect(DateTime.parse(page.css('tr')[0].css('td')[5].inner_text).instance_of?(DateTime))
    end

  end

end
