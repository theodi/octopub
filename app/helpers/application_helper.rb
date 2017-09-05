module ApplicationHelper

  def selected_dataset_file_schema_id(dataset_file, default = 0)
    if dataset_file.new_record?
      default
    else
      dataset_file.dataset_file_schema ? dataset_file.dataset_file_schema.id : default
    end
  end

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

  class CodeRayify < Redcarpet::Render::HTML
    def block_code(code, language)
      CodeRay.scan(code, language).div
    end
  end

  def markdown(text)
      coderayified = CodeRayify.new(filter_html: true,  hard_wrap: true)
      options = {
          fenced_code_blocks: true,
          no_intra_emphasis: true,
          autolink: true,
          strikethrough: true,
          lax_html_blocks: true,
          superscript: true
      }
      markdown_to_html = Redcarpet::Markdown.new(coderayified, options)
      markdown_to_html.render(text).html_safe
  end

  def markdown_json(json_text)
    pretty_json = JSON.pretty_generate JSON.parse(json_text)
    markdown("```json\n#{pretty_json}")
  end

  def pusher_cluster
    Rails.configuration.pusher_cluster if Rails.configuration.respond_to?(:pusher_cluster)
  end
  
  def dataset_file_schema_access_options
    [["Private - only you can access this schema", true],["Public - any user may access this schema",false]]
  end
  
end
