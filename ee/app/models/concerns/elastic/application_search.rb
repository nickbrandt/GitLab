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

      settings \
        index: {
          number_of_shards: AsJSON.new { Gitlab::CurrentSettings.elasticsearch_shards },
          number_of_replicas: AsJSON.new { Gitlab::CurrentSettings.elasticsearch_replicas },
          codec: 'best_compression',
          analysis: {
            analyzer: {
              default: {
                tokenizer: 'standard',
                filter: %w(standard lowercase my_stemmer)
              },
              my_ngram_analyzer: {
                tokenizer: 'my_ngram_tokenizer',
                filter: ['lowercase']
              }
            },
            filter: {
              my_stemmer: {
                type: 'stemmer',
                name: 'light_english'
              }
            },
            tokenizer: {
              my_ngram_tokenizer: {
                type: 'nGram',
                min_gram: 2,
                max_gram: 3,
                token_chars: %w(letter digit)
              }
            }
          }
        }

      # Since we can't have multiple types in ES6, but want to be able to use JOINs, we must declare all our
      # fields together instead of per model
      mappings dynamic: 'strict' do
        ### Shared fields
        indexes :id, type: :integer
        indexes :created_at, type: :date
        indexes :updated_at, type: :date

        # ES6-compatible way of having a parent, this is shared with all
        # Please note that if we add a parent to `project` we'll have to use that "grand-parent" as the routing value
        # for all children of project - therefore it is not advised.
        indexes :join_field, type: :join,
                             relations: {
                               project: %i(
                                 issue
                                 merge_request
                                 milestone
                                 note
                                 blob
                                 wiki_blob
                                 commit
                               )
                             }
        # ES6 requires a single type per index, so we implement our own "type"
        indexes :type, type: :keyword

        indexes :iid, type: :integer

        indexes :title, type: :text,
                        index_options: 'offsets'
        indexes :description, type: :text,
                              index_options: 'offsets'
        indexes :state, type: :text
        indexes :project_id, type: :integer
        indexes :author_id, type: :integer

        ## Projects and Snippets
        indexes :visibility_level, type: :integer

        ### ISSUES
        indexes :confidential, type: :boolean

        # The field assignee_id does not exist in issues table anymore.
        # Nevertheless we'll keep this field as is because we don't want users to rebuild index
        # + the ES treats arrays transparently so
        # to any integer field you can write any array of integers and you don't have to change mapping.
        # More over you can query those items just like a single integer value.
        indexes :assignee_id, type: :integer

        ### MERGE REQUESTS
        indexes :target_branch, type: :text,
                                index_options: 'offsets'
        indexes :source_branch, type: :text,
                                index_options: 'offsets'
        indexes :merge_status, type: :text
        indexes :source_project_id, type: :integer
        indexes :target_project_id, type: :integer

        ### NOTES
        indexes :note, type: :text,
                       index_options: 'offsets'

        indexes :issue do
          indexes :assignee_id, type: :integer
          indexes :author_id, type: :integer
          indexes :confidential, type: :boolean
        end

        # ES6 gets rid of "index: :not_analyzed" option, but a keyword type behaves the same
        # as it is not analyzed and is only searchable by its exact value.
        indexes :noteable_type, type: :keyword
        indexes :noteable_id, type: :keyword

        ### PROJECTS
        indexes :name, type: :text,
                       index_options: 'offsets'
        indexes :path, type: :text,
                       index_options: 'offsets'
        indexes :name_with_namespace, type: :text,
                                      index_options: 'offsets',
                                      analyzer: :my_ngram_analyzer
        indexes :path_with_namespace, type: :text,
                                      index_options: 'offsets'
        indexes :namespace_id, type: :integer
        indexes :archived, type: :boolean

        indexes :issues_access_level, type: :integer
        indexes :merge_requests_access_level, type: :integer
        indexes :snippets_access_level, type: :integer
        indexes :wiki_access_level, type: :integer
        indexes :repository_access_level, type: :integer

        indexes :last_activity_at, type: :date
        indexes :last_pushed_at, type: :date

        ### SNIPPETS
        indexes :file_name, type: :text,
                            index_options: 'offsets'
        indexes :content, type: :text,
                          index_options: 'offsets'

        ### REPOSITORIES
        indexes :blob do
          indexes :type, type: :keyword

          indexes :id, type: :text,
                       index_options: 'offsets',
                       analyzer: :sha_analyzer
          indexes :rid, type: :keyword
          indexes :oid, type: :text,
                        index_options: 'offsets',
                        analyzer: :sha_analyzer
          indexes :commit_sha, type: :text,
                               index_options: 'offsets',
                               analyzer: :sha_analyzer
          indexes :path, type: :text,
                         analyzer: :path_analyzer
          indexes :file_name, type: :text,
                              analyzer: :code_analyzer,
                              search_analyzer: :code_search_analyzer
          indexes :content, type: :text,
                            index_options: 'offsets',
                            analyzer: :code_analyzer,
                            search_analyzer: :code_search_analyzer
          indexes :language, type: :keyword
        end

        indexes :commit do
          indexes :type, type: :keyword

          indexes :id, type: :text,
                       index_options: 'offsets',
                       analyzer: :sha_analyzer
          indexes :rid, type: :keyword
          indexes :sha, type: :text,
                        index_options: 'offsets',
                        analyzer: :sha_analyzer

          indexes :author do
            indexes :name, type: :text, index_options: 'offsets'
            indexes :email, type: :text, index_options: 'offsets'
            indexes :time, type: :date, format: :basic_date_time_no_millis
          end

          indexes :committer do
            indexes :name, type: :text, index_options: 'offsets'
            indexes :email, type: :text, index_options: 'offsets'
            indexes :time, type: :date, format: :basic_date_time_no_millis
          end

          indexes :message, type: :text, index_options: 'offsets'
        end
      end

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

      def es_import(options = {})
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
        conditions = [pick_projects_by_membership(project_ids, features)]

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
      def pick_projects_by_membership(project_ids, features = nil)
        condition =
          if project_ids == :any
            { term: { visibility_level: Project::PRIVATE } }
          else
            { terms: { id: project_ids } }
          end

        limit_by_feature(condition, features, include_members_only: true)
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
    end
  end
end
