# frozen_string_literal: true

module Elastic
  module Latest
    module GitClassProxy
      def elastic_search(query, type: :all, page: 1, per: 20, options: {})
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

      private

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

        res = search(query_hash)
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

        res = search(query_hash)

        {
          results: res.results,
          total_count: res.size
        }
      end
    end
  end
end
