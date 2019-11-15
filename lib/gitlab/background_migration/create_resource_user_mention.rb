# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    class CreateResourceUserMention
      # Resources that have mentions to be migrated:
      # issue, merge_request, epic, commit, snippet, design

      BULK_INSERT_SIZE = 5000

      class EpicUserMention < ActiveRecord::Base
        self.table_name = 'epic_user_mentions'

        def self.resource_foreign_key
          "epic_id"
        end
      end

      class IssueUserMention < ActiveRecord::Base
        self.table_name = 'issue_user_mentions'

        def self.resource_foreign_key
          "issue_id"
        end
      end
      class MergeRequestUserMention < ActiveRecord::Base
        self.table_name = 'merge_request_user_mentions'

        def self.resource_foreign_key
          "merge_request_id"
        end
      end

      class CommitUserMention < ActiveRecord::Base
        self.table_name = 'commit_user_mentions'

        def self.resource_foreign_key
          "commit_id"
        end
      end

      module DesignManagement
        class DesignUserMention < ActiveRecord::Base
          self.table_name = 'design_user_mentions'

          def self.resource_foreign_key
            "design_id"
          end
        end
      end

      class SnippetUserMention < ActiveRecord::Base
        self.table_name = 'snippet_user_mentions'

        def self.resource_foreign_key
          "snippet_id"
        end
      end

      def perform(resource_model, join, conditions, with_notes, start_id, end_id)
        resource_model              = resource_model.constantize if resource_model.is_a?(String)
        model                       = with_notes ? Note : resource_model
        resource_user_mention_model = "Gitlab::BackgroundMigration::CreateResourceUserMention::#{resource_model}UserMention".constantize

        records = model.joins(join).where(conditions).where(id: start_id..end_id)

        records.in_groups_of(BULK_INSERT_SIZE, false).each do |records|
          mentions = []
          records.each do |record|
            mentions << resource_mention_values(record, resource_user_mention_model, with_notes)
          end

          no_quote_columns = [:note_id]
          no_quote_columns << "#{resource_user_mention_model.resource_foreign_key}".to_sym unless resource_model.to_s == 'Commit'

          Gitlab::Database.bulk_insert(
            resource_user_mention_model.table_name,
            mentions,
            return_ids: true,
            disable_quote: no_quote_columns,
            on_conflict: :do_nothing
          )
        end
      end

      private

      def resource_mention_values(record, resource_user_mention_model, with_notes)
        refs = record.all_references(record.author)

        {
          "#{resource_user_mention_model.resource_foreign_key}": user_mention_resource_id(record, with_notes),
          note_id: user_mention_note_id(record, with_notes),
          mentioned_users_ids: array_to_sql(refs.mentioned_users.pluck(:id)),
          mentioned_projects_ids: array_to_sql(refs.mentioned_projects.pluck(:id)),
          mentioned_groups_ids: array_to_sql(refs.mentioned_groups.pluck(:id))
        }
      end

      def array_to_sql(ids_array)
        ids_array.presence.to_s.sub('[', '{').sub(']', '}').presence
      end

      def user_mention_resource_id(record, with_notes)
        with_notes ? record.noteable_id || record.commit_id : record.id
      end

      def user_mention_note_id(record, with_notes)
        with_notes ? record.id : 'NULL'
      end
    end
  end
end
