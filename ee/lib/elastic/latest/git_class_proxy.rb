# frozen_string_literal: true

module Elastic
  module Latest
    module GitClassProxy
      SHA_REGEX = /\A[0-9a-f]{5,40}\z/i.freeze

      def elastic_search(query, type: 'all', page: 1, per: 20, options: {})
        results = { blobs: [], commits: [] }

        case type
        when 'all'
          results[:blobs] = search_blob(query, page: page, per: per, options: options)
          results[:commits] = search_commit(query, page: page, per: per, options: options)
          results[:wiki_blobs] = search_blob(query, type: 'wiki_blob', page: page, per: per, options: options)
        when 'commit'
          results[:commits] = search_commit(query, page: page, per: per, options: options)
        when 'blob', 'wiki_blob'
          results[type.pluralize.to_sym] = search_blob(query, type: type, page: page, per: per, options: options)
        end

        results
      end

      # @return [Kaminari::PaginatableArray]
      def elastic_search_as_found_blob(query, page: 1, per: 20, options: {})
        # Highlight is required for parse_search_result to locate relevant line
        options = options.merge(highlight: true)

        elastic_search_and_wrap(query, type: es_type, page: page, per: per, options: options) do |result, project|
          ::Gitlab::Elastic::SearchResults.parse_search_result(result, project)
        end
      end

      private

      def extract_repository_ids(options)
        [options[:repository_id]].flatten
      end

      def search_commit(query, page: 1, per: 20, options: {})
        page ||= 1

        fields = %w(message^10 sha^5 author.name^2 author.email^2 committer.name committer.email).map {|i| "commit.#{i}"}

        query_with_prefix = query.split(/\s+/).map { |s| s.gsub(SHA_REGEX) { |sha| "#{sha}*" } }.join(' ')

        query_hash = {
          query: {
            bool: {
              must: {
                simple_query_string: {
                  fields: fields,
                  query: query_with_prefix,
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

        repository_ids = extract_repository_ids(options)
        if repository_ids.any?
          query_hash[:query][:bool][:filter] << {
            terms: {
              'commit.rid' => repository_ids
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

        res = search(query_hash, options)
        {
          results: res.results,
          total_count: res.size
        }
      end

      def search_blob(query, type: 'blob', page: 1, per: 20, options: {})
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

        repository_ids = extract_repository_ids(options)
        if repository_ids.any?
          query_hash[:query][:bool][:filter] << {
            terms: {
              'blob.rid' => repository_ids
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

        options[:project_ids] = repository_ids.map { |id| id.to_s[/\d+/].to_i } if type == 'wiki_blob' && repository_ids.any?

        res = search(query_hash, options)

        {
          results: res.results,
          total_count: res.size
        }
      end

      # Wrap returned results into GitLab model objects and paginate
      #
      # @return [Kaminari::PaginatableArray]
      def elastic_search_and_wrap(query, type:, page: 1, per: 20, options: {}, &blk)
        response = elastic_search(
          query,
          type: type,
          page: page,
          per: per,
          options: options
        )[type.pluralize.to_sym][:results]

        items, total_count = yield_each_search_result(response, type, &blk)

        # Before "map" we had a paginated array so we need to recover it
        offset = per * ((page || 1) - 1)
        Kaminari.paginate_array(items, total_count: total_count, limit: per, offset: offset)
      end

      def yield_each_search_result(response, type)
        # Avoid one SELECT per result by loading all projects into a hash
        project_ids = response.map { |result| project_id_for_commit_or_blob(result, type) }.uniq
        projects = Project.with_route.id_in(project_ids).index_by(&:id)
        total_count = response.total_count

        items = response.map do |result|
          project_id = project_id_for_commit_or_blob(result, type)
          project = projects[project_id]

          if project.nil? || project.pending_delete?
            total_count -= 1
            next
          end

          yield(result, project)
        end

        # Remove results for deleted projects
        items.compact!

        [items, total_count]
      end

      # Indexed commit does not include project_id
      def project_id_for_commit_or_blob(result, type)
        result.dig('_source', 'project_id') || result.dig('_source', type, 'rid').to_i
      end
    end
  end
end
