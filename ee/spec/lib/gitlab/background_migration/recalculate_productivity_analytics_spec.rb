# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::BackgroundMigration::RecalculateProductivityAnalytics, migration: true, schema: 20190802012622 do
  include MigrationHelpers::RecalculateProductivityAnalyticsHelpers

  let(:background_migration) { described_class.new }

  describe '#perform' do
    let(:merged_at_after) { 6.weeks.ago }

    subject { background_migration.perform(*id_boundaries) }

    let(:id_boundaries) do
      [merged_mr.id, open_mr.id].minmax
    end

    let(:merged_mr) { create_populated_mr(user, project, metrics: { merged_at: merged_at_after + 1.week }) }
    let(:open_mr) { create_populated_mr(user, project) }

    let(:user) do
      table(:users).create!(
        email: 'sample_user@user.com',
        projects_limit: 10,
        name: 'Test User',
        username: 'sample_user'
      )
    end

    let(:bot) do
      table(:users).create!(
        email: 'bot@bot.com',
        projects_limit: 10,
        name: 'Test Bot',
        username: 'sample_bot',
        bot_type: 1 # support bot
      )
    end

    let(:group) { table(:namespaces).create!(path: 'test_group', name: 'test_group') }

    let(:project) do
      table(:projects).create!(name: 'test project', path: 'test_project', namespace_id: group.id, creator_id: user.id)
    end

    it 'updates productivity metrics for merged MRs' do
      Timecop.freeze(Time.zone.now.change(nsec: 0)) do
        merged_mr
        expect { subject }
          .to change {
            table(:merge_request_metrics).find_by(merge_request_id: merged_mr.id).attributes.slice(*described_class::METRICS_TO_CALCULATE)
          }.to({ "commits_count" => 2, "diff_size" => 20, "first_comment_at" => 4.weeks.ago + 1.day, "first_commit_at" => 4.weeks.ago, "last_commit_at" => 1.week.ago, "modified_paths_size" => 2 })
      end
    end

    it 'does not update productivity metrics for open MR' do
      open_mr
      expect { subject }
        .not_to change {
          table(:merge_request_metrics).find_by(merge_request_id: open_mr.id).attributes.slice(*described_class::METRICS_TO_CALCULATE)
        }
    end
  end
end
