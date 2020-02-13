# frozen_string_literal: true

class SnippetBlobPresenter < BlobPresenter
  include Gitlab::Routing

  def rich_data
    return if blob.binary?
    return unless blob.rich_viewer

    render_rich_partial
  end

  def plain_data
    return if blob.binary?

    highlight(plain: false)
  end

  def raw_path
    if snippet.is_a?(ProjectSnippet)
      raw_project_snippet_path(snippet.project, snippet)
    else
      raw_snippet_path(snippet)
    end
  end

  private

  def snippet
    blob.container
  end

  def language
    nil
  end

  def render_rich_partial
    renderer.render("projects/blob/viewers/#{blob.rich_viewer.partial_name}",
                    viewer: blob.rich_viewer,
                    blob: blob,
                    blow_raw_path: raw_path)
  end

  def renderer
    ActionView::Base.new(build_lookup_context, { snippet: snippet }, ActionController::Base.new).tap do |renderer|
      renderer.extend ApplicationController._helpers
      renderer.class_eval do
        include Rails.application.routes.url_helpers
      end
    end
  end

  def build_lookup_context
    ActionView::Base.build_lookup_context(ActionController::Base.view_paths)
  end
end
