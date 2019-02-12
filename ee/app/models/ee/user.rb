# frozen_string_literal: true

module EE
  # User EE mixin
  #
  # This module is intended to encapsulate EE-specific model logic
  # and be prepended in the `User` model
  module User
    extend ActiveSupport::Concern
    extend ::Gitlab::Utils::Override

    include AuditorUserHelper

    DEFAULT_ROADMAP_LAYOUT = 'months'.freeze
    DEFAULT_GROUP_VIEW = 'details'.freeze

    prepended do
      EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM = 1

      # We aren't using the `auditor?` method for the `if` condition here
      # because `auditor?` returns `false` when the `auditor` column is `true`
      # and the auditor add-on absent. We want to run this validation
      # regardless of the add-on's presence, so we need to check the `auditor`
      # column directly.
      validate :auditor_requires_license_add_on, if: :auditor
      validate :cannot_be_admin_and_auditor

      delegate :shared_runners_minutes_limit, :shared_runners_minutes_limit=,
               to: :namespace

      has_many :reviews,                  foreign_key: :author_id, inverse_of: :author
      has_many :epics,                    foreign_key: :author_id
      has_many :assigned_epics,           foreign_key: :assignee_id, class_name: "Epic"
      has_many :path_locks,               dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :vulnerability_feedback, foreign_key: :author_id, class_name: 'Vulnerabilities::Feedback'

      has_many :approvals,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent
      has_many :approvers,                dependent: :destroy # rubocop: disable Cop/ActiveRecordDependent

      has_many :developer_groups, -> { where(members: { access_level: ::Gitlab::Access::DEVELOPER }) }, through: :group_members, source: :group

      has_many :users_ops_dashboard_projects
      has_many :ops_dashboard_projects, through: :users_ops_dashboard_projects, source: :project

      has_many :group_saml_identities, -> { where.not(saml_provider_id: nil) }, source: :identities, class_name: ::Identity

      # Protected Branch Access
      has_many :protected_branch_merge_access_levels, dependent: :destroy, class_name: ::ProtectedBranch::MergeAccessLevel # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_push_access_levels, dependent: :destroy, class_name: ::ProtectedBranch::PushAccessLevel # rubocop:disable Cop/ActiveRecordDependent
      has_many :protected_branch_unprotect_access_levels, dependent: :destroy, class_name: ::ProtectedBranch::UnprotectAccessLevel # rubocop:disable Cop/ActiveRecordDependent

      has_many :smartcard_identities

      scope :excluding_guests, -> { joins(:members).where('members.access_level > ?', ::Gitlab::Access::GUEST).distinct }

      scope :subscribed_for_admin_email, -> { where(admin_email_unsubscribed_at: nil) }
      scope :ldap, -> { joins(:identities).where('identities.provider LIKE ?', 'ldap%') }
      scope :with_provider, ->(provider) do
        joins(:identities).where(identities: { provider: provider })
      end

      accepts_nested_attributes_for :namespace

      enum roadmap_layout: { weeks: 1, months: 4, quarters: 12 }

      # User's Group preference
      # Note: When adding an option, it's value MUST equal to the last value + 1.
      enum group_view: { details: 1, security_dashboard: 2 }, _prefix: true
      scope :group_view_details, -> { where('group_view = ? OR group_view IS NULL', group_view[:details]) }
    end

    class_methods do
      def support_bot
        email_pattern = "support%s@#{Settings.gitlab.host}"

        unique_internal(where(support_bot: true), 'support-bot', email_pattern) do |u|
          u.bio = 'The GitLab support bot used for Service Desk'
          u.name = 'GitLab Support Bot'
        end
      end

      # override
      def internal_attributes
        super + [:support_bot]
      end

      def non_ldap
        joins('LEFT JOIN identities ON identities.user_id = users.id')
          .where('identities.provider IS NULL OR identities.provider NOT LIKE ?', 'ldap%')
      end

      def find_by_smartcard_identity(certificate_subject, certificate_issuer)
        joins(:smartcard_identities)
          .find_by(smartcard_identities: { subject: certificate_subject, issuer: certificate_issuer })
      end
    end

    def cannot_be_admin_and_auditor
      if admin? && auditor?
        errors.add(:admin, "user cannot also be an Auditor.")
      end
    end

    def auditor_requires_license_add_on
      unless license_allows_auditor_user?
        errors.add(:auditor, 'user cannot be created without the "GitLab_Auditor_User" addon')
      end
    end

    def auditor?
      self.auditor && license_allows_auditor_user?
    end

    def access_level
      if auditor?
        :auditor
      else
        super
      end
    end

    def access_level=(new_level)
      new_level = new_level.to_s
      return unless %w(admin auditor regular).include?(new_level)

      self.admin = (new_level == 'admin')
      self.auditor = (new_level == 'auditor')
    end

    # Does the user have access to all private groups & projects?
    def full_private_access?
      super || auditor?
    end

    def email_opted_in_source
      email_opted_in_source_id == EMAIL_OPT_IN_SOURCE_ID_GITLAB_COM ? 'GitLab.com' : ''
    end

    def available_custom_project_templates(search: nil, subgroup_id: nil)
      templates = ::Gitlab::CurrentSettings.available_custom_project_templates(subgroup_id)

      ::ProjectsFinder.new(current_user: self,
                           project_ids_relation: templates,
                           params: { search: search, sort: 'name_asc' })
                      .execute
    end

    def available_subgroups_with_custom_project_templates(group_id = nil)
      groups = group_id ? ::Group.find(group_id).self_and_ancestors : ::Group.all

      GroupsFinder.new(self, min_access_level: ::Gitlab::Access::MAINTAINER)
                  .execute
                  .where(id: groups.with_project_templates.select(:custom_project_templates_group_id))
                  .includes(:projects)
                  .reorder(nil)
                  .distinct
    end

    def roadmap_layout
      super || DEFAULT_ROADMAP_LAYOUT
    end

    def group_view
      super || DEFAULT_GROUP_VIEW
    end

    override :several_namespaces?
    def several_namespaces?
      union_sql = ::Gitlab::SQL::Union.new(
        [owned_groups,
         maintainers_groups,
         groups_with_developer_maintainer_project_access]).to_sql

      ::Group.from("(#{union_sql}) #{::Group.table_name}").any?
    end

    override :manageable_groups
    def manageable_groups(include_groups_with_developer_maintainer_access: false)
      owned_and_maintainer_group_hierarchy = super()

      if include_groups_with_developer_maintainer_access
        union_sql = ::Gitlab::SQL::Union.new(
          [owned_and_maintainer_group_hierarchy,
           groups_with_developer_maintainer_project_access]).to_sql

        ::Group.from("(#{union_sql}) #{::Group.table_name}")
      else
        owned_and_maintainer_group_hierarchy
      end
    end

    def groups_with_developer_maintainer_project_access
      project_creation_levels = [::EE::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS]

      if ::Gitlab::CurrentSettings.default_project_creation == ::EE::Gitlab::Access::DEVELOPER_MAINTAINER_PROJECT_ACCESS
        project_creation_levels << nil
      end

      developer_groups_hierarchy = ::Gitlab::ObjectHierarchy.new(developer_groups).base_and_descendants
      ::Group.where(id: developer_groups_hierarchy.select(:id),
                    project_creation_level: project_creation_levels)
    end

    def any_namespace_with_trial?
      ::Namespace
        .from("(#{namespace_union(:trial_ends_on)}) #{::Namespace.table_name}")
        .where('trial_ends_on > ?', Time.now.utc)
        .any?
    end

    def any_namespace_with_gold?
      ::Namespace
        .includes(:plan)
        .where("namespaces.id IN (#{namespace_union})") # rubocop:disable GitlabSecurity/SqlInjection
        .where.not(plans: { id: nil })
        .any?
    end

    override :has_current_license?
    def has_current_license?
      License.current.present?
    end

    def group_sso?(group)
      return false unless group

      if group_saml_identities.loaded?
        group_saml_identities.any? { |identity| identity.saml_provider.group_id == group.id }
      else
        group_saml_identities.where(saml_provider: group.saml_provider).any?
      end
    end

    override :ldap_sync_time
    def ldap_sync_time
      ::Gitlab.config.ldap['sync_time']
    end

    def admin_unsubscribe!
      update_column :admin_email_unsubscribed_at, Time.now
    end

    private

    def namespace_union(select = :id)
      ::Gitlab::SQL::Union.new([
        ::Namespace.select(select).where(type: nil, owner: self),
        owned_groups.select(select).where(parent_id: nil)
      ]).to_sql
    end
  end
end
