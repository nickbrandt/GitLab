# frozen_string_literal: true

class JiraConnect::ConfigurationController < JiraConnect::ApplicationController
  before_action :allow_rendering_in_iframe

  def show
    sample_html = <<~HEREDOC
      <!DOCTYPE html>
      <html lang="en">
        <head>
          <link rel="stylesheet" href="https://unpkg.com/@atlaskit/css-reset@2.0.0/dist/bundle.css" media="all">
          <script src="https://connect-cdn.atl-paas.net/all.js" async></script>
        </head>
        <body>
          <section id="content" class="ac-content" style="padding: 20px;">
            <h1>Hello from GitLab!</h1>
          </section>
        </body>
      </html>
    HEREDOC

    render html: sample_html.html_safe
  end

  private

  def allow_rendering_in_iframe
    response.headers.delete('X-Frame-Options')
  end
end
