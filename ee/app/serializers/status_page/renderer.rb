# frozen_string_literal: true

module StatusPage
  module Renderer
    def self.markdown(object, field, issue_iid:)
      context = (issue_iid: issue_iid, post_process_pipeline: StatusPage::PostProcessPipeline)
      MarkupHelper.markdown_field(object, field, context)
    end
  end
end
