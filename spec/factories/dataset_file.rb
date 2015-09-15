FactoryGirl.define do
  factory :dataset_file do
    title 'My Awesome Dataset'
    filename 'dataset.csv'
    description Faker::Company.bs
    mediatype 'text/csv'
  end
end
