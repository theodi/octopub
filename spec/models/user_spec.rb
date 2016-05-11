require 'spec_helper'

describe User do

  context "find_for_github_oauth" do

    before(:each) do
      @auth = {
        "provider" => "github",
        "uid" => "1213232",
        "info" => {
          "nickname" => "user-mcuser",
          "email" => "user@example.com"
        },
        "credentials" => {
          "token" => "21312313233"
        }
      }
    end

    it "creates a user from Github oauth" do
      user = User.find_for_github_oauth(@auth)

      expect(user.name).to eq("user-mcuser")
      expect(user.email).to eq("user@example.com")
      expect(user.token).to eq("21312313233")
      expect(user.api_key).to match /[a-z0-9]{20}/
    end

    it "finds a user from Github oauth" do
      user = create(:user, provider: "github", uid: "1213232")

      found_user = User.find_for_github_oauth(@auth)

      expect(found_user).to eq(user)
    end

  end

end
