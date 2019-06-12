# frozen_string_literal: true

module Geo
  class LegacyAttachmentRegistryFinder < RegistryFinder
    def syncable
      attachments.syncable
    end

    private

    def attachments
      current_node.attachments
    end
  end
end
