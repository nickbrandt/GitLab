# frozen_string_literal: true

# # frozen_string_literal: true
#
# module StatusPage
#   module Renderer
#     def self.process(html, issue_iid:)
#       Banzai.post_process(
#         html,
#         project: nil,
#         post_process_pipeline: :'::_banzai::_pipeline::_status_page::_post_process',
#         issue_iid: issue_iid
#       )
#     end
#   end
# end

# frozen_string_literal: true

module StatusPage
  module Renderer
    def self.post_process(html, issue_iid:)
      Banzai.post_process(
        html,
        project: nil,
        pipeline: nil,
        post_process_pipeline: :'::_banzai::_pipeline::_status_page::_post_process',
        issue_iid: issue_iid
      )
    end
  end
end
