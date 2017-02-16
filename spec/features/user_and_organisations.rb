RSpec.shared_context 'user and organisations', shared_context: :metadata do
  let(:organizations) {
    [
      OpenStruct.new(
        organization: OpenStruct.new({
          login: "org1",
          avatar_url: "http://www.example.org/avatar1.png"
        })
      ),
      OpenStruct.new(
        organization: OpenStruct.new({
          login: "org2",
          avatar_url: "http://www.example.org/avatar2.png"
        })
      ),
      OpenStruct.new(
        organization: OpenStruct.new({
          login: "org3",
          avatar_url: "http://www.example.org/avatar3.png"
        })
      )
    ]
  }

  let(:github_user) {
    OpenStruct.new(
      avatar_url: "http://www.example.org/avatar2.png"
    )
  }
end
