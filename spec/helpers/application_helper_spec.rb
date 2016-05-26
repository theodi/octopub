require 'spec_helper'

describe ApplicationHelper do

  before(:each) do
    @user = create(:user)

    allow(helper).to receive(:current_user) {
      @user
    }

    allow(@user).to receive(:organizations) {
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

    allow(@user).to receive(:github_user) {
      OpenStruct.new(
        avatar_url: "http://www.example.org/avatar2.png"
      )
    }
  end

  it 'gets organization options' do
    expect(helper.organization_options).to eq(
      [
        [
          'org1',
          'org1',
          { 'data-content' => "<img src='http://www.example.org/avatar1.png' height='20' width='20' /> org1" }
        ],
        [
          'org2',
          'org2',
          { 'data-content' => "<img src='http://www.example.org/avatar2.png' height='20' width='20' /> org2" }
        ],
        [
          'org3',
          'org3',
          { 'data-content' => "<img src='http://www.example.org/avatar3.png' height='20' width='20' /> org3" }
        ]
      ]
    )
  end

  it 'gets user option' do
    expect(helper.user_option).to eq(
      [
        'user',
        nil,
        { 'data-content' => "<img src='http://www.example.org/avatar2.png' height='20' width='20' /> user" }
      ]
    )
  end

  it 'gets all options' do
    expect(helper.organization_select_options).to eq([
      [
        'user',
        nil,
        { 'data-content' => "<img src='http://www.example.org/avatar2.png' height='20' width='20' /> user" }
      ],
      [
        'org1',
        'org1',
        { 'data-content' => "<img src='http://www.example.org/avatar1.png' height='20' width='20' /> org1" }
      ],
      [
        'org2',
        'org2',
        { 'data-content' => "<img src='http://www.example.org/avatar2.png' height='20' width='20' /> org2" }
      ],
      [
        'org3',
        'org3',
        { 'data-content' => "<img src='http://www.example.org/avatar3.png' height='20' width='20' /> org3" }
      ]
    ])
  end

end
