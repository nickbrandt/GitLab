# frozen_string_literal: true

module EE
  module AuditEvent
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    # While tracking events that could take place even when
    # a user is not logged in, (eg: downloading repo of a public project),
    # we set the author_id of such events as -1
    UNAUTH_USER_AUTHOR_ID = -1
    # Events that are authored by unathenticated users, should be
    # shown as authored by `An unauthenticated user` in the UI.
    UNAUTH_USER_AUTHOR_NAME = 'An unauthenticated user'.freeze

    override :author_name
    def author_name
      if (author_name = details[:author_name].presence || user&.name)
        author_name
      elsif authored_by_unauth_user?
        UNAUTH_USER_AUTHOR_NAME
      end
    end

    def entity
      return unless entity_type && entity_id

      # Avoiding exception if the record doesn't exist
      @entity ||= entity_type.constantize.find_by_id(entity_id) # rubocop:disable Gitlab/ModuleWithInstanceVariables
    end

    def present
      AuditEventPresenter.new(self)
    end

    def authored_by_unauth_user?
      author_id == UNAUTH_USER_AUTHOR_ID
    end
  end
end
