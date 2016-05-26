module ApplicationHelper

  def organization_options
    current_user.organizations.collect { |o|
      [
        o.organization.login,
        o.organization.login,
        { 'data-content' => "<img src='#{o.organization.avatar_url}' height='20' width='20' /> #{o.organization.login}" }
      ]
    }
  end

  def user_option
    [
      current_user.github_username,
      nil,
      { 'data-content' => "<img src='#{current_user.github_user.avatar_url}' height='20' width='20' /> #{current_user.github_username}" }
    ]
  end

  def organization_select_options
    organization_options.unshift(user_option)
  end

end
