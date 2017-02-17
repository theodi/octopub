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

  def user_option_with_username
    [
      current_user.github_username,
      current_user.id,
      { 'data-content' => "<img src='#{current_user.github_user.avatar_url}' height='20' width='20' /> #{current_user.github_username}" }
    ]
  end

  def organization_select_options
    organization_options.unshift(user_option)
  end

  def organization_select_options_schema
    organization_options.unshift(user_option_with_username)
    [ user_option_with_username ]
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

end
