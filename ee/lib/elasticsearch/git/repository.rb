# frozen_string_literal: true

module Elasticsearch
  module Git
    module Repository
      CreateIndexException = Class.new(StandardError)

      BLOBS_BATCH = 100
      COMMMITS_BATCH = 500

      extend ActiveSupport::Concern

      included do
        include Elasticsearch::Git::Model
        include Elasticsearch::Git::EncoderHelper

        def es_parent
          "project_#{project_id}"
        end

        def es_type
          'blob'
        end

        # Indexing all text-like blobs in repository
        #
        # All data stored in global index
        # Repository can be selected by 'rid' field
        # If you want - this field can be used for store 'project' id
        #
        # blob {
        #   id - uniq id of blob from all repositories
        #   oid - blob id in repository
        #   content - blob content
        #   commit_sha - last actual commit sha
        # }
        #
        # For search from blobs use type 'blob'
        def index_blobs(from_rev: nil, to_rev: repository_for_indexing.last_commit.oid)
          from, to = parse_revs(from_rev, to_rev)

          diff = repository_for_indexing.diff(from, to)
          deltas = diff.deltas

          deltas.reverse.each_slice(BLOBS_BATCH) do |slice|
            bulk_operations = slice.map do |delta|
              if delta.status == :deleted
                next if delta.old_file[:mode].to_s(8) == "160000"

                b = LiteBlob.new(repository_for_indexing, delta.old_file)
                delete_blob(b)
              else
                next if delta.new_file[:mode].to_s(8) == "160000"

                b = LiteBlob.new(repository_for_indexing, delta.new_file)
                index_blob(b, to)
              end
            end

            perform_bulk bulk_operations

            yield slice, deltas.length if block_given?
          end

          ObjectSpace.garbage_collect
        end

        def perform_bulk(bulk_operations)
          bulk_operations.compact!

          return false if bulk_operations.empty?

          client_for_indexing.bulk body: bulk_operations
        end

        def delete_blob(blob)
          return unless blob.text?

          {
            delete: {
              _index: "#{self.class.index_name}",
              _type: 'doc',
              _id: "#{repository_id}_#{blob.path}",
              routing: es_parent
            }
          }
        end

        def index_blob(blob, target_sha)
          return unless can_index_blob?(blob)

          {
            index:  {
              _index: "#{self.class.index_name}",
              _type: 'doc',
              _id: "#{repository_id}_#{blob.path}",
              routing: es_parent,
              data: {
                blob: {
                  oid: blob.id,
                  rid: repository_id,
                  content: blob.data,
                  commit_sha: target_sha,
                  path: blob.path,

                  # We're duplicating file_name parameter here because
                  # we need another analyzer for it.
                  # Ideally this should be done with copy_to: 'blob.file_name' option
                  # but it does not work in ES v2.3.*. We're doing it so to not make users
                  # install newest versions
                  # https://github.com/elastic/elasticsearch-mapper-attachments/issues/124
                  file_name: blob.path,
                  # Linguist is not available in the Ruby indexer. The Go indexer can
                  # fill in the right language.
                  language: nil
                },
                type: es_type,
                join_field: {
                  'name' => es_type,
                  'parent' => es_parent

                }
              }
            }
          }
        end

        # Index text-like files which size less 1.mb
        def can_index_blob?(blob)
          blob.text_in_repo? && (blob.size && blob.size.to_i < 1048576)
        end

        # Indexing all commits in repository
        #
        # All data stored in global index
        # Repository can be filtered by 'rid' field
        # If you want - this field can be used git store 'project' id
        #
        # commit {
        #  sha - commit sha
        #  author {
        #    name - commit author name
        #    email - commit author email
        #    time - commit time
        #  }
        #  committer {
        #    name - committer name
        #    email - committer email
        #    time - commit time
        #  }
        #  message - commit message
        # }
        #
        # For search from commits use type 'commit'
        def index_commits(from_rev: nil, to_rev: repository_for_indexing.last_commit.oid)
          from, to = parse_revs(from_rev, to_rev)
          range = [from, to].compact.join('..')
          out, err, status = Open3.capture3("git log #{range} --format=\"%H\"", chdir: repository_for_indexing.path)

          if status.success? && err.blank?
            # TODO: use rugged walker!!!
            commit_oids = out.split("\n")

            commit_oids.each_slice(COMMMITS_BATCH) do |batch|
              bulk_operations = batch.map do |commit|
                index_commit(repository_for_indexing.lookup(commit))
              end

              perform_bulk bulk_operations

              yield batch, commit_oids.length if block_given?
            end

            ObjectSpace.garbage_collect
          end
        end

        def index_commit(commit)
          author    = commit.author
          committer = commit.committer

          {
            index:  {
              _index: "#{self.class.index_name}",
              _type: 'doc',
              _id: "#{repository_id}_#{commit.oid}",
              routing: es_parent,
              data: {
                commit: {
                  rid: repository_id,
                  sha: commit.oid,
                  author: {
                    name: encode!(author[:name]),
                    email: encode!(author[:email]),
                    time: author[:time].strftime('%Y%m%dT%H%M%S%z')
                  },
                  committer: {
                    name: encode!(committer[:name]),
                    email: encode!(committer[:email]),
                    time: committer[:time].strftime('%Y%m%dT%H%M%S%z')
                  },
                  message: encode!(commit.message)
                },
                type: 'commit',
                join_field: {
                  'name' => 'commit',
                  'parent' => es_parent
                }
              }
            }
          }
        end

        def parse_revs(from_rev, to_rev)
          from = if index_new_branch?(from_rev)
                   if to_rev == repository_for_indexing.last_commit.oid
                     nil
                   else
                     repository_for_indexing.merge_base(
                       to_rev,
                       repository_for_indexing.last_commit.oid
                     )
                   end
                 else
                   from_rev
                 end

          [from, to_rev]
        end

        def index_new_branch?(from)
          from == '0000000000000000000000000000000000000000'
        end

        # Representation of repository as indexed json
        # Attention: It can be very very very huge hash
        def as_indexed_json(options = {})
          data = {}
          data[:blobs] = index_blobs_array
          data[:commits] = index_commits_array
          data
        end

        # Indexing blob from current index
        def index_blobs_array
          result = []

          target_sha = repository_for_indexing.head.target.oid

          if repository_for_indexing.bare?
            tree = repository_for_indexing.lookup(target_sha).tree
            result.push(recurse_blobs_index_hash(tree))
          else
            repository_for_indexing.index.each do |blob|
              b = LiteBlob.new(repository_for_indexing, blob)

              if b.text?
                result.push(
                  {
                    id: "#{target_sha}_#{b.path}",
                    rid: repository_id,
                    oid: b.id,
                    content: b.data,
                    commit_sha: target_sha
                  })
              end
            end
          end

          result
        end

        def recurse_blobs_index_hash(tree, path = "")
          result = []

          tree.each_blob do |blob|
            blob[:path] = path + blob[:name]
            b = LiteBlob.new(repository_for_indexing, blob)

            if b.text?
              result.push(
                {
                  id: "#{repository_for_indexing.head.target.oid}_#{path}#{blob[:name]}",
                  rid: repository_id,
                  oid: b.id,
                  content: b.data,
                  commit_sha: repository_for_indexing.head.target.oid
                })
            end
          end

          tree.each_tree do |nested_tree|
            result.push(recurse_blobs_index_hash(repository_for_indexing.lookup(nested_tree[:oid]), "#{nested_tree[:name]}/"))
          end

          result.flatten
        end

        # Lookup all object ids for commit objects
        def index_commits_array
          res = []

          repository_for_indexing.each_id do |oid|
            obj = repository_for_indexing.lookup(oid)
            if obj.type == :commit
              res.push(
                {
                  sha: obj.oid,
                  author: obj.author,
                  committer: obj.committer,
                  message: encode!(obj.message)
                }
              )
            end
          end

          res
        end

        def search(query, type: :all, page: 1, per: 20, options: {})
          options[:repository_id] = repository_id if options[:repository_id].nil?
          self.class.search(query, type: type, page: page, per: per, options: options)
        end

        # Repository id used for identity data from different repositories
        # Update this value if needed
        def set_repository_id(id = nil)
          @repository_id = id || path_to_repo
        end

        # For Overwrite
        def repository_id
          @repository_id
        end

        unless method_defined?(:path_to_repo)
          def path_to_repo
            @path_to_repo.presence || raise(NotImplementedError, 'Please, define "path_to_repo" method, or set "path_to_repo" via "repository_for_indexing" method')
          end
        end

        def repository_for_indexing(repo_path = nil)
          return @rugged_repo_indexer if defined? @rugged_repo_indexer

          # Gitaly: how are we going to migrate ES code search? https://gitlab.com/gitlab-org/gitaly/issues/760
          @path_to_repo ||= allow_disk_access { repo_path || path_to_repo }

          set_repository_id

          @rugged_repo_indexer = Rugged::Repository.new(@path_to_repo)
        end

        def client_for_indexing
          @client_for_indexing ||= Elasticsearch::Client.new retry_on_failure: 5
        end

        def allow_disk_access
          # Sometimes this code runs as part of a bin/elastic_repo_indexer
          # process. When that is the case Gitlab::GitalyClient::StorageSettings
          # is not defined.
          if defined?(Gitlab::GitalyClient::StorageSettings)
            Gitlab::GitalyClient::StorageSettings.allow_disk_access do
              yield
            end
          else
            yield
          end
        end
      end

      class_methods do
        def search(query, type: :all, page: 1, per: 20, options: {})
          results = { blobs: [], commits: [] }

          case type.to_sym
          when :all
            results[:blobs] = search_blob(query, page: page, per: per, options: options)
            results[:commits] = search_commit(query, page: page, per: per, options: options)
            results[:wiki_blobs] = search_blob(query, type: :wiki_blob, page: page, per: per, options: options)
          when :commit
            results[:commits] = search_commit(query, page: page, per: per, options: options)
          when :blob, :wiki_blob
            results[type.to_s.pluralize.to_sym] = search_blob(query, type: type, page: page, per: per, options: options)
          end

          results
        end

        def search_commit(query, page: 1, per: 20, options: {})
          page ||= 1

          fields = %w(message^10 sha^5 author.name^2 author.email^2 committer.name committer.email).map {|i| "commit.#{i}"}

          query_hash = {
            query: {
              bool: {
                must: {
                  simple_query_string: {
                    fields: fields,
                    query: query,
                    default_operator: :and
                  }
                },
                filter: [{ term: { 'type' => 'commit' } }]
              }
            },
            size: per,
            from: per * (page - 1)
          }

          if query.blank?
            query_hash[:query][:bool][:must] = { match_all: {} }
            query_hash[:track_scores] = true
          end

          if options[:repository_id]
            query_hash[:query][:bool][:filter] << {
              terms: {
                'commit.rid' => [options[:repository_id]].flatten
              }
            }
          end

          if options[:additional_filter]
            query_hash[:query][:bool][:filter] << options[:additional_filter]
          end

          if options[:highlight]
            es_fields = fields.map { |field| field.split('^').first }.each_with_object({}) do |field, memo|
              memo[field.to_sym] = {}
            end

            query_hash[:highlight] = {
              pre_tags: ["gitlabelasticsearch→"],
              post_tags: ["←gitlabelasticsearch"],
              fields: es_fields
            }
          end

          options[:order] = :default if options[:order].blank?

          query_hash[:sort] = [:_score]

          res = self.__elasticsearch__.search(query_hash)
          {
            results: res.results,
            total_count: res.size
          }
        end

        def search_blob(query, type: :blob, page: 1, per: 20, options: {})
          page ||= 1

          query = ::Gitlab::Search::Query.new(query) do
            filter :filename, field: :file_name
            filter :path, parser: ->(input) { "*#{input.downcase}*" }
            filter :extension, field: :path, parser: ->(input) { '*.' + input.downcase }
          end

          query_hash = {
            query: {
              bool: {
                must: {
                  simple_query_string: {
                    query: query.term,
                    default_operator: :and,
                    fields: %w[blob.content blob.file_name]
                  }
                },
                filter: [
                  { term: { type: type } }
                ]
              }
            },
            size: per,
            from: per * (page - 1)
          }

          query_hash[:query][:bool][:filter] += query.elasticsearch_filters(:blob)

          if options[:repository_id]
            query_hash[:query][:bool][:filter] << {
              terms: {
                'blob.rid' => [options[:repository_id]].flatten
              }
            }
          end

          if options[:additional_filter]
            query_hash[:query][:bool][:filter] << options[:additional_filter]
          end

          if options[:language]
            query_hash[:query][:bool][:filter] << {
              terms: {
                'blob.language' => [options[:language]].flatten
              }
            }
          end

          options[:order] = :default if options[:order].blank?

          query_hash[:sort] = [:_score]

          if options[:highlight]
            query_hash[:highlight] = {
              pre_tags: ["gitlabelasticsearch→"],
              post_tags: ["←gitlabelasticsearch"],
              order: "score",
              fields: {
                "blob.content" => {},
                "blob.file_name" => {}
              }
            }
          end

          res = self.__elasticsearch__.search(query_hash)

          {
            results: res.results,
            total_count: res.size
          }
        end
      end
    end
  end
end
