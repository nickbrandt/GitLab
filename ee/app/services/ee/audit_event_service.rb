# frozen_string_literal: true

module EE
  module AuditEventService
    extend ::Gitlab::Utils::Override
    # rubocop:disable Gitlab/ModuleWithInstanceVariables
    def for_member(member)
      action = @details[:action]
      old_access_level = @details[:old_access_level]
      user_id = member.id
      user_name = member.user ? member.user.name : 'Deleted User'

      @details =
        case action
        when :destroy
          {
            remove: "user_access",
            author_name: @author.name,
            target_id: user_id,
            target_type: "User",
            target_details: user_name
          }
        when :expired
          {
            remove: "user_access",
            author_name: member.created_by ? member.created_by.name : 'Deleted User',
            target_id: user_id,
            target_type: "User",
            target_details: user_name,
            system_event: true,
            reason: "access expired on #{member.expires_at}"
          }
        when :create
          {
            add: "user_access",
            as: ::Gitlab::Access.options_with_owner.key(member.access_level.to_i),
            author_name: @author.name,
            target_id: user_id,
            target_type: "User",
            target_details: user_name
          }
        when :update, :override
          {
            change: "access_level",
            from: old_access_level,
            to: member.human_access,
            expiry_from: @details[:old_expiry],
            expiry_to: member.expires_at,
            author_name: @author.name,
            target_id: user_id,
            target_type: "User",
            target_details: user_name
          }
        end

      self
    end

    def for_project_group_link(group_link)
      @details = custom_project_link_group_attributes(group_link)
                 .merge(author_name: @author.name,
                        target_id: group_link.project.id,
                        target_type: 'Project',
                        target_details: group_link.project.full_path)

      self
    end

    def for_failed_login
      ip = @details[:ip_address]
      auth = @details[:with] || 'STANDARD'

      @details = {
        failed_login: auth.upcase,
        author_name: @author,
        target_details: @author,
        ip_address: ip
      }

      self
    end

    def for_changes
      @details =
        {
            change: @details[:as] || @details[:column],
            from: @details[:from],
            to: @details[:to],
            author_name: @author.name,
            target_id: @entity.id,
            target_type: @entity.class.name,
            target_details: @details[:target_details] || @entity.name
        }
      self
    end

    def security_event
      prepare_security_event

      super if enabled?
    end

    def prepare_security_event
      if admin_audit_log_enabled?
        add_security_event_admin_details!
      end
    end

    def unauth_security_event
      return unless audit_events_enabled?

      @details.delete(:ip_address) unless admin_audit_log_enabled?
      @details[:entity_path] = @entity&.full_path if admin_audit_log_enabled?

      SecurityEvent.create(
        author_id: @author.respond_to?(:id) ? @author.id : AuditEvent::UNAUTH_USER_AUTHOR_ID,
        entity_id: @entity.respond_to?(:id) ? @entity.id : -1,
        entity_type: 'User',
        details: @details
      )
    end

    def for_project
      for_custom_model('project', @entity.full_path)
    end

    def for_group
      for_custom_model('group', @entity.full_path)
    end

    def enabled?
      admin_audit_log_enabled? ||
        audit_events_enabled? ||
        entity_audit_events_enabled?
    end

    def entity_audit_events_enabled?
      @entity.respond_to?(:feature_available?) && @entity.feature_available?(:audit_events)
    end

    def audit_events_enabled?
      # Always log auth events. Log all other events if `extended_audit_events` is enabled
      @details[:with] || License.feature_available?(:extended_audit_events)
    end

    def admin_audit_log_enabled?
      License.feature_available?(:admin_audit_log)
    end

    def method_missing(method_sym, *arguments, &block)
      super(method_sym, *arguments, &block) unless respond_to?(method_sym)

      for_custom_model(method_sym.to_s.split('for_').last, *arguments)
    end

    def respond_to?(method, include_private = false)
      method.to_s.start_with?('for_') || super
    end

    private

    override :base_payload
    def base_payload
      {
        author_id: @author.respond_to?(:id) ? @author.id : AuditEvent::UNAUTH_USER_AUTHOR_ID,
        # `@author.respond_to?(:id)` is to support cases where we need to log events
        # that could take place even when a user is unathenticated, Eg: downloading a public repo.
        # For such events, it is not mandatory that an author is always present.
        entity_id: @entity.id,
        entity_type: @entity.class.name
      }
    end

    def for_custom_model(model, key_title)
      action = @details[:action]
      model_class = model.camelize
      custom_message = @details[:custom_message]

      @details =
        case action
        when :destroy
          {
              remove: model,
              author_name: @author.name,
              target_id: key_title,
              target_type: model_class,
              target_details: key_title
          }
        when :create
          {
              add: model,
              author_name: @author.name,
              target_id: key_title,
              target_type: model_class,
              target_details: key_title
          }
        when :custom
          {
              custom_message: custom_message,
              author_name: @author&.name,
              target_id: key_title,
              target_type: model_class,
              target_details: key_title,
              ip_address: @details[:ip_address]
          }
        end

      self
    end

    def ip_address
      @author&.current_sign_in_ip || @details[:ip_address]
    end

    def add_security_event_admin_details!
      @details.merge!(ip_address: ip_address,
                      entity_path: @entity.full_path)
    end

    def custom_project_link_group_attributes(group_link)
      case @details[:action]
      when :destroy
        { remove: 'project_access' }
      when :create
        {
          add: 'project_access',
          as: group_link.human_access
        }
      when :update
        {
          change: 'access_level',
          from: @details[:old_access_level],
          to: group_link.human_access
        }
      end
    end
    # rubocop:enable Gitlab/ModuleWithInstanceVariables
  end
end
