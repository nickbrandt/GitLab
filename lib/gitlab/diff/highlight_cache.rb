# frozen_string_literal: true
#
module Gitlab
  module Diff
    class HighlightCache
      EXPIRATION = 1.week

      delegate :diffable,     to: :@diff_collection
      delegate :diff_options, to: :@diff_collection

      def initialize(diff_collection, backend: Rails.cache)
        @backend          = backend
        @diff_collection  = diff_collection
      end

      # - Reads from cache
      # - Assigns DiffFile#highlighted_diff_lines for cached files
      def decorate(diff_file)
        if content = read_file(diff_file)
          diff_file.highlighted_diff_lines = content.map do |line|
            Gitlab::Diff::Line.init_from_hash(line)
          end
        end
      end

      def write_if_empty
        diff_files = @diff_collection.diff_files
        cached_diff_files = read_cache
        uncached_files = diff_files.select { |file| cached_diff_files[file.file_path].nil? }

        return if uncached_files.empty?

        new_cache_content = {}
        uncached_files.each do |diff_file|
          next unless cacheable?(diff_file)

          new_cache_content[diff_file.file_path] = diff_file.highlighted_diff_lines.map(&:to_hash)
        end

        write_to_redis_hash(new_cache_content)
      end

      # Given a hash of:
      #   { "file/to/cache" =>
      #   [ { line_code: "a5cc2925ca8258af241be7e5b0381edf30266302_19_19",
      #       rich_text: " <span id=\"LC19\" class=\"line\" lang=\"plaintext\">config/initializers/secret_token.rb</span>\n",
      #       text: " config/initializers/secret_token.rb",
      #       type: nil,
      #       index: 3,
      #       old_pos: 19,
      #       new_pos: 19 }
      #   ] }
      #
      #   ...it will write/update a Redis hash (HSET)
      #
      def write_to_redis_hash(hash)
        Redis::Cache.with do |redis|
          redis.multi do |multi|
            hash.each do |diff_file_id, highlighted_diff_lines_hash|
              multi.hset(key, diff_file_id, highlighted_diff_lines_hash.to_json)
            end

            # HSETs have to have their expiration date manually updated
            #
            multi.expire(key, EXPIRATION)
          end
        end
      end

      def read_single_entry_from_redis_hash(diff_file_id)
        Redis::Cache.with do |redis|
          redis.hget(key, diff_file_id)
        end
      end

      def clear
        Redis::Cache.with do |redis|
          redis.del(key)
        end
      end

      def key
        @redis_key ||= ['highlighted-diff-files', diffable.cache_key, VERSION, diff_options].join(":")
      end

      private

      def file_paths
        @file_paths ||= @diff_collection.diffs.collect(&:file_path)
      end

      def read_file(diff_file)
        cached_content[diff_file.file_path]
      end

      def cached_content
        @cached_content ||= read_cache
      end

      def read_cache
        return {} unless file_paths.any?

        results = []

        Redis::Cache.with do |redis|
          results = redis.hmget(key, file_paths)
        end

        results.map! do |result|
          JSON.parse(result, symbolize_names: true) unless result.nil?
        end

        file_paths.zip(results).to_h
      end

      def cacheable?(diff_file)
        diffable.present? && diff_file.text? && diff_file.diffable?
      end
    end
  end
end
