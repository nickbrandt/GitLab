# frozen_string_literal: true
# rubocop:disable Style/Documentation

module Gitlab
  module BackgroundMigration
    module UserMentions
      class CreateResourceUserMention
        # Resources that have mentions to be migrated:
        # issue, merge_request, epic, commit, snippet, design

        BULK_INSERT_SIZE = 5000

        def perform(resource_model, join, conditions, with_notes, start_id, end_id)
          isolation_module = "Gitlab::BackgroundMigration::UserMentions::Models"
          resource_model              = "#{isolation_module}::#{resource_model}".constantize if resource_model.is_a?(String)
          model                       = with_notes ? "#{isolation_module}::Note".constantize : resource_model
          resource_user_mention_model = "Gitlab::BackgroundMigration::UserMentions::Models::#{resource_model.name.demodulize}UserMention".constantize

          records = model.joins(join).where(conditions).where(id: start_id..end_id)

          records.in_groups_of(BULK_INSERT_SIZE, false).each do |records|
            mentions = []
            records.each do |record|
              mentions << resource_mention_values(record, resource_user_mention_model, with_notes)
            end

            no_quote_columns = [:note_id]
            no_quote_columns << "#{resource_user_mention_model.resource_foreign_key}".to_sym unless resource_model.to_s.end_with?('Commit')

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
end
