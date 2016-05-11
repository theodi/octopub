class FakeData
  def save
  end

  def add_file(filename, file)
  end

  def update_file(filename, file)
  end

  def delete_file(filename)
  end
end

FactoryGirl.define do
  factory :dataset do
    name "My Awesome Dataset"
    description "An awesome dataset"
    publisher_name "Awesome Inc"
    publisher_url "http://awesome.com"
    license "OGL-UK-3.0"
    frequency "One-off"

    association :user, factory: :user

    after(:build) { |dataset|
      dataset.class.skip_callback(:create, :before, :create_in_github)
      dataset.instance_variable_set(:@repo, FakeData.new)
    }

    trait :with_callback do
      after(:build) { |dataset|
        dataset.class.set_callback(:create, :before, :create_in_github)
      }
    end
  end
end
