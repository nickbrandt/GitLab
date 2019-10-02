# frozen_string_literal: true
module Elastic
  module ApplicationSearch
    extend ActiveSupport::Concern

    # Defer evaluation from class-definition time to index-creation time
    class AsJSON
      def initialize(&blk)
        @blk = blk
      end

      def call
        @blk.call
      end

      def as_json(*args, &blk)
        call
      end
    end

    included do
      include Elasticsearch::Model

      index_name [Rails.application.class.parent_name.downcase, Rails.env].join('-')

      # ES6 requires a single type per index
      document_type 'doc'

      # A temp solution to keep only one copy of setting,
      # will be removed in https://gitlab.com/gitlab-org/gitlab-ee/issues/12548
      __elasticsearch__.instance_variable_set(:@settings, Elastic::Latest::Config.settings)
      __elasticsearch__.instance_variable_set(:@mapping, Elastic::Latest::Config.mappings)

      after_commit on: :create do
        if Gitlab::CurrentSettings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(:index, self.class.to_s, self.id, self.es_id)
        end
      end

      after_commit on: :update do
        if Gitlab::CurrentSettings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(
            :update,
            self.class.to_s,
            self.id,
            self.es_id,
            changed_fields: self.previous_changes.keys
          )
        end
      end

      after_commit on: :destroy do
        if Gitlab::CurrentSettings.elasticsearch_indexing? && self.searchable?
          ElasticIndexerWorker.perform_async(
            :delete,
            self.class.to_s,
            self.id,
            self.es_id,
            es_parent: self.es_parent
          )
        end
      end

      # Should be overridden in the models where some records should be skipped
      def searchable?
        self.use_elasticsearch?
      end

      def use_elasticsearch?
        self.project&.use_elasticsearch?
      end

      def generic_attributes
        {
          'join_field' => {
            'name' => es_type,
            'parent' => es_parent
          },
          'type' => es_type
        }
      end

      def es_parent
        "project_#{project_id}" unless is_a?(Project) || self&.project_id.nil?
      end

      def es_type
        self.class.es_type
      end

      def es_id
        "#{es_type}_#{id}"
      end

      # Some attributes are actually complicated methods. Bad data can cause
      # them to raise exceptions. When this happens, we still want the remainder
      # of the object to be saved, so silently swallow the errors
      def safely_read_attribute_for_elasticsearch(attr_name)
        send(attr_name) # rubocop:disable GitlabSecurity/PublicSend
      rescue => err
        logger.warn("Elasticsearch failed to read #{attr_name} for #{self.class} #{self.id}: #{err}")
        nil
      end
    end

    class_methods do
      # Support STI models
      def inherited(subclass)
        super

        # Avoid SystemStackError in Model.import
        # See https://github.com/elastic/elasticsearch-rails/issues/144
        subclass.include Elasticsearch::Model

        # Use ES configuration from parent model
        # TODO: Revisit after upgrading to elasticsearch-model 7.0.0
        # See https://github.com/elastic/elasticsearch-rails/commit/b8455db186664e21927bfb271bab6390853e7ff3
        subclass.__elasticsearch__.index_name = self.index_name
        subclass.__elasticsearch__.document_type = self.document_type
        subclass.__elasticsearch__.instance_variable_set(:@mapping, self.mapping.dup)
      end

      # Should be overridden for all nested models
      def nested?
        false
      end

      def es_type
        name.underscore
      end

      def highlight_options(fields)
        es_fields = fields.map { |field| field.split('^').first }.each_with_object({}) do |field, memo|
          memo[field.to_sym] = {}
        end

        { fields: es_fields }
      end

      def es_import(**options)
        transform = lambda do |r|
          { index: { _id: r.es_id, data: r.__elasticsearch__.as_indexed_json } }.tap do |data|
            data[:index][:routing] = r.es_parent if r.es_parent
          end
        end

        options[:transform] = transform

        self.import(options)
      end

      def basic_query_hash(fields, query)
        query_hash = if query.present?
                       {
                         query: {
                           bool: {
                             must: [{
                               simple_query_string: {
                                 fields: fields,
                                 query: query,
                                 default_operator: :and
                               }
                             }],
                             filter: [{
                               term: { type: self.es_type }
                             }]
                           }
                         }
                       }
                     else
                       {
                         query: {
                           bool: {
                             must: { match_all: {} }
                           }
                         },
                         track_scores: true
                       }
                     end

        query_hash[:sort] = [
          { updated_at: { order: :desc } },
          :_score
        ]

        query_hash[:highlight] = highlight_options(fields)

        query_hash
      end

      def iid_query_hash(iid)
        {
          query: {
            bool: {
               filter: [{ term: { iid: iid } }]
            }
          }
        }
      end

      # Builds an elasticsearch query that will select child documents from a
      # set of projects, taking user access rules into account.
      def project_ids_filter(query_hash, options)
        project_query = project_ids_query(
          options[:current_user],
          options[:project_ids],
          options[:public_and_internal_projects],
          options[:features]
        )

        query_hash[:query][:bool][:filter] ||= []
        query_hash[:query][:bool][:filter] << {
          has_parent: {
            parent_type: "project",
            query: {
              bool: project_query
            }
          }
        }

        query_hash
      end

      # Builds an elasticsearch query that will select projects the user is
      # granted access to.
      #
      # If a project feature(s) is specified, it indicates interest in child
      # documents gated by that project feature - e.g., "issues". The feature's
      # visibility level must be taken into account.
      def project_ids_query(user, project_ids, public_and_internal_projects, features = nil)
        # When reading cross project is not allowed, only allow searching a
        # a single project, so the `:read_*` ability is only checked once.
        unless Ability.allowed?(user, :read_cross_project)
          project_ids = [] if project_ids.is_a?(Array) && project_ids.size > 1
        end

        # At least one condition must be present, so pick no projects for
        # anonymous users.
        # Pick private, internal and public projects the user is a member of.
        # Pick all private projects for admins & auditors.
        conditions = [pick_projects_by_membership(project_ids, user, features)]

        if public_and_internal_projects
          # Skip internal projects for anonymous and external users.
          # Others are given access to all internal projects. Admins & auditors
          # get access to internal projects where the feature is private.
          conditions << pick_projects_by_visibility(Project::INTERNAL, user, features) if user && !user.external?

          # All users, including anonymous, can access public projects.
          # Admins & auditors get access to public projects where the feature is
          # private.
          conditions << pick_projects_by_visibility(Project::PUBLIC, user, features)
        end

        { should: conditions }
      end

      private

      # Most users come with a list of projects they are members of, which may
      # be a mix of public, internal or private. Grant access to them all, as
      # long as the project feature is not disabled.
      #
      # Admins & auditors are given access to all private projects. Access to
      # internal or public projects where the project feature is private is not
      # granted here.
      def pick_projects_by_membership(project_ids, user, features = nil)
        if features.nil?
          if project_ids == :any
            return { term: { visibility_level: Project::PRIVATE } }
          else
            return { terms: { id: project_ids } }
          end
        end

        Array(features).map do |feature|
          condition =
            if project_ids == :any
              { term: { visibility_level: Project::PRIVATE } }
            else
              { terms: { id: filter_ids_by_feature(project_ids, user, feature) } }
            end

          limit =
            { terms: { "#{feature}_access_level" => [::ProjectFeature::ENABLED, ::ProjectFeature::PRIVATE] } }

          { bool: { filter: [condition, limit] } }
        end
      end

      # Grant access to projects of the specified visibility level to the user.
      #
      # If a project feature is specified, access is only granted if the feature
      # is enabled or, for admins & auditors, private.
      def pick_projects_by_visibility(visibility, user, features)
        condition = { term: { visibility_level: visibility } }

        limit_by_feature(condition, features, include_members_only: user&.full_private_access?)
      end

      # If a project feature(s) is specified, access is dependent on its visibility
      # level being enabled (or private if `include_members_only: true`).
      #
      # This method is a no-op if no project feature is specified.
      # It accepts an array of features or a single feature, when an array is provided
      # it queries if any of the features is enabled.
      #
      # Always denies access to projects when the features are disabled - even to
      # admins & auditors - as stale child documents may be present.
      def limit_by_feature(condition, features, include_members_only:)
        return condition unless features

        features = Array(features)

        features.map do |feature|
          limit =
            if include_members_only
              { terms: { "#{feature}_access_level" => [::ProjectFeature::ENABLED, ::ProjectFeature::PRIVATE] } }
            else
              { term: { "#{feature}_access_level" => ::ProjectFeature::ENABLED } }
            end

          { bool: { filter: [condition, limit] } }
        end
      end

      def filter_ids_by_feature(project_ids, user, feature)
        Project
          .id_in(project_ids)
          .filter_by_feature_visibility(feature, user)
          .pluck_primary_key
      end
    end
  end
end
