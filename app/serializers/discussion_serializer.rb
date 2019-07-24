# frozen_string_literal: true

class DiscussionSerializer < BaseSerializer
  entity DiscussionEntity

  def represent(resource, opts = {}, entity_class = nil)
    super(resource, with_additional_opts(opts), entity_class)
  end

  private

  def with_additional_opts(opts)
    return opts unless @request.project

    additional_opts = {
      submodule_links: Gitlab::SubmoduleLinks.new(@request.project.repository)
    }

    opts.merge(additional_opts)
  end
end
