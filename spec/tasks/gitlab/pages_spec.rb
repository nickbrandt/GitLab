# frozen_string_literal: true

require 'rake_helper'

describe 'rake gitlab:pages:fix_pages_access_control_setting_on_gitlab_com' do
  using RSpec::Parameterized::TableSyntax
  before do
    Rake.application.rake_require 'tasks/gitlab/pages'
    stub_pages_setting(access_control: true)
  end

  subject do
    run_rake_task('gitlab:pages:fix_pages_access_control_setting_on_gitlab_com')
  end

  let(:migration_name) { 'FixGitlabComPagesAccessLevelBatch' }

  it 'schedules background migrations' do
    Sidekiq::Testing.fake! do
      Timecop.freeze do
        first_id = create(:project).id
        last_id = create(:project).id

        subject

        expect(migration_name).to be_scheduled_delayed_migration(2.minutes, first_id, last_id)
      end
    end
  end

  where(:visibility_level, :pages_access_level,
        :pages_deployed, :ac_is_enabled_in_config,
        :result_pages_access_level) do
    # Does not change anything if pages are not deployed
    Project::PRIVATE  | ProjectFeature::DISABLED | false | false | ProjectFeature::DISABLED
    Project::PRIVATE  | ProjectFeature::PRIVATE  | false | false | ProjectFeature::PRIVATE
    Project::PRIVATE  | ProjectFeature::ENABLED  | false | false | ProjectFeature::ENABLED
    Project::PRIVATE  | ProjectFeature::PUBLIC   | false | false | ProjectFeature::PUBLIC
    Project::INTERNAL | ProjectFeature::DISABLED | false | false | ProjectFeature::DISABLED
    Project::INTERNAL | ProjectFeature::PRIVATE  | false | false | ProjectFeature::PRIVATE
    Project::INTERNAL | ProjectFeature::ENABLED  | false | false | ProjectFeature::ENABLED
    Project::INTERNAL | ProjectFeature::PUBLIC   | false | false | ProjectFeature::PUBLIC
    Project::PUBLIC   | ProjectFeature::DISABLED | false | false | ProjectFeature::DISABLED
    Project::PUBLIC   | ProjectFeature::PRIVATE  | false | false | ProjectFeature::PRIVATE
    Project::PUBLIC   | ProjectFeature::ENABLED  | false | false | ProjectFeature::ENABLED
    Project::PUBLIC   | ProjectFeature::PUBLIC   | false | false | ProjectFeature::PUBLIC

    # Does not change anything if pages are already private in config.json
    # many of these cases are invalid and will not occur in production
    Project::PRIVATE  | ProjectFeature::DISABLED | true | true | ProjectFeature::DISABLED
    Project::PRIVATE  | ProjectFeature::PRIVATE  | true | true | ProjectFeature::PRIVATE
    Project::PRIVATE  | ProjectFeature::ENABLED  | true | true | ProjectFeature::ENABLED
    Project::PRIVATE  | ProjectFeature::PUBLIC   | true | true | ProjectFeature::PUBLIC
    Project::INTERNAL | ProjectFeature::DISABLED | true | true | ProjectFeature::DISABLED
    Project::INTERNAL | ProjectFeature::PRIVATE  | true | true | ProjectFeature::PRIVATE
    Project::INTERNAL | ProjectFeature::ENABLED  | true | true | ProjectFeature::ENABLED
    Project::INTERNAL | ProjectFeature::PUBLIC   | true | true | ProjectFeature::PUBLIC
    Project::PUBLIC   | ProjectFeature::DISABLED | true | true | ProjectFeature::DISABLED
    Project::PUBLIC   | ProjectFeature::PRIVATE  | true | true | ProjectFeature::PRIVATE
    Project::PUBLIC   | ProjectFeature::ENABLED  | true | true | ProjectFeature::ENABLED
    Project::PUBLIC   | ProjectFeature::PUBLIC   | true | true | ProjectFeature::PUBLIC

    # when pages are deployed and ac is disabled in config
    Project::PRIVATE  | ProjectFeature::DISABLED | true | false | ProjectFeature::DISABLED
    Project::PRIVATE  | ProjectFeature::PRIVATE  | true | false | ProjectFeature::PUBLIC   # need to update
    Project::PRIVATE  | ProjectFeature::ENABLED  | true | false | ProjectFeature::PUBLIC   # invalid state, need to update
    Project::PRIVATE  | ProjectFeature::PUBLIC   | true | false | ProjectFeature::PUBLIC
    Project::INTERNAL | ProjectFeature::DISABLED | true | false | ProjectFeature::DISABLED
    Project::INTERNAL | ProjectFeature::PRIVATE  | true | false | ProjectFeature::PUBLIC   # need to update
    Project::INTERNAL | ProjectFeature::ENABLED  | true | false | ProjectFeature::PUBLIC   # invalid state, need to update
    Project::INTERNAL | ProjectFeature::PUBLIC   | true | false | ProjectFeature::PUBLIC
    Project::PUBLIC   | ProjectFeature::DISABLED | true | false | ProjectFeature::DISABLED
    Project::PUBLIC   | ProjectFeature::PRIVATE  | true | false | ProjectFeature::ENABLED  # need to update
    Project::PUBLIC   | ProjectFeature::ENABLED  | true | false | ProjectFeature::ENABLED
    Project::PUBLIC   | ProjectFeature::PUBLIC   | true | false | ProjectFeature::ENABLED  # invalid state, need to update
  end

  with_them do
    it 'fixes settings' do
      perform_enqueued_jobs do
        project = create_project(visibility_level, pages_access_level, pages_deployed, ac_is_enabled_in_config)

        expect(project.reload.project_feature.pages_access_level).to eq(pages_access_level)

        subject

        expect(project.reload.project_feature.pages_access_level).to eq(result_pages_access_level)
      end
    end
  end

  def create_project(visibility_level, pages_access_level, pages_deployed, ac_is_enabled_in_config)
    project = create(:project)

    if pages_deployed
      FileUtils.mkdir_p(project.public_pages_path)

      # write config.json
      allow(project).to receive(:public_pages?).and_return(!ac_is_enabled_in_config)
      Projects::UpdatePagesConfigurationService.new(project).execute
    end

    project.update!(visibility_level: visibility_level)
    project.project_feature.update!(pages_access_level: pages_access_level)

    project
  end
end
