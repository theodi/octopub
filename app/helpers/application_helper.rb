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
      [
        o.organization.login,
        o.organization.login,
        { 'data-content' => "<img src='#{o.organization.avatar_url}' height='20' width='20' /> #{o.organization.login}" }
      ]
    }
  end

  def user_organization_option
    [
      current_user.github_username,
      current_user.github_username,
      { 'data-content' => "<img src='#{current_user.github_user.avatar_url}' height='20' width='20' /> #{current_user.github_username}" }
    ]
  end

  def organization_select_options
    organization_options.unshift(user_organization_option)
  end

  def user_select_options(users)
    users.collect do |user|
      [
        user.name,
        user.id,
        { 'data-content' => user.name }
      ]
    end
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

  def time_or_date(date)
    date.today? ? date.strftime('Today') : date.strftime('%d-%m-%Y')
  end

end
