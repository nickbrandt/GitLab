# frozen_string_literal: true

module Elastic
  module Latest
    module Config
      # To obtain settings and mappings methods
      extend Elasticsearch::Model::Indexing::ClassMethods
      extend Elasticsearch::Model::Naming::ClassMethods

      self.index_name = [Rails.application.class.parent_name.downcase, Rails.env].join('-')

      # ES6 requires a single type per index
      self.document_type = 'doc'

      settings \
        index: {
          number_of_shards: Elastic::AsJSON.new { Gitlab::CurrentSettings.elasticsearch_shards },
          number_of_replicas: Elastic::AsJSON.new { Gitlab::CurrentSettings.elasticsearch_replicas },
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
              },
              path_analyzer: {
                type: 'custom',
                tokenizer: 'path_tokenizer',
                filter: %w(lowercase asciifolding)
              },
              sha_analyzer: {
                type: 'custom',
                tokenizer: 'sha_tokenizer',
                filter: %w(lowercase asciifolding)
              },
              code_analyzer: {
                type: 'custom',
                tokenizer: 'whitespace',
                filter: %w(code edgeNGram_filter lowercase asciifolding)
              },
              code_search_analyzer: {
                type: 'custom',
                tokenizer: 'whitespace',
                filter: %w(lowercase asciifolding)
              }
            },
            filter: {
              my_stemmer: {
                type: 'stemmer',
                name: 'light_english'
              },
              code: {
                type: "pattern_capture",
                preserve_original: true,
                patterns: [
                  "(\\p{Ll}+|\\p{Lu}\\p{Ll}+|\\p{Lu}+)",
                  "(\\d+)",
                  "(?=([\\p{Lu}]+[\\p{L}]+))",
                  '"((?:\\"|[^"]|\\")*)"', # capture terms inside quotes, removing the quotes
                  "'((?:\\'|[^']|\\')*)'", # same as above, for single quotes
                  '\.([^.]+)(?=\.|\s|\Z)', # separate terms on periods
                  '\/?([^\/]+)(?=\/|\b)' # separate path terms (like/this/one)
                ]
              },
              edgeNGram_filter: {
                type: 'edgeNGram',
                min_gram: 2,
                max_gram: 40
              }
            },
            tokenizer: {
              my_ngram_tokenizer: {
                type: 'nGram',
                min_gram: 2,
                max_gram: 3,
                token_chars: %w(letter digit)
              },
              sha_tokenizer: {
                type: "edgeNGram",
                min_gram: 5,
                max_gram: 40,
                token_chars: %w(letter digit)
              },
              path_tokenizer: {
                type: 'path_hierarchy',
                reverse: true
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
    end
  end
end
