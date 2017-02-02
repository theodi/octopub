module ApplicationHelper

  def organization_options
    current_user.organizations.collect { |o|
      str = "<img src='#{o.organization.avatar_url}' height='20' width='20' /> #{o.organization.login}"
      if o.organization.restricted
        str += " <i class='fa fa-lock'></i>"
      end
      [
        o.organization.login,
        o.organization.login,
        {
          'data-content' => str,
          'data-restricted' => o.organization.restricted
        }
      ]
    }
  end

  def user_option
    str = "<img src='#{current_user.github_user.avatar_url}' height='20' width='20' /> #{current_user.github_username}"
    if current_user.can_create_private_repos?
      str += " <i class='fa fa-lock'></i>"
    end
    [
      current_user.github_username,
      nil,
      {
        'data-content' => str,
        'data-restricted' => current_user.can_create_private_repos?
      }
    ]
  end

  def organization_select_options
    organization_options.unshift(user_option)
  end

end
