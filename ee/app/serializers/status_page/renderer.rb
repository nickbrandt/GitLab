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

# module StatusPage
#   module Renderer
#     def self.post_process(html, issue_iid:)
#       Banzai.post_process(
#         html,
#         project: nil,
#         pipeline: nil,
#         user: nil,
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
        user: nil,
        post_process_pipeline: :'::_status_page::_post_process', # TODO switch to class
        issue_iid: issue_iid
      )
    end

    # Reusable formatter for post processing HTML in Status Page entities.
    #
    # Example:
    #
    #   class MyEntity < Grape::Entity
    #     include StatusPage::Renderer::GrapeFormatter
    #
    #     expose :title_html, as: :title, format_with: :post_process
    #   end
    module GrapeFormatter
      extend ActiveSupport::Concern

      included do
        format_with :post_processed_html do |html|
          StatusPage::Renderer.post_process(html, issue_iid: options[:issue_iid])
        end
      end
    end
  end
end
