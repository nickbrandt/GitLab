# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Freeze Periods (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers
  include Ci::PipelineSchedulesHelper

  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) { create(:project, :repository, path: 'freeze-periods-project') }
  let_it_be(:freeze_period_1) { create(:ci_freeze_period, project: project, freeze_start: '5 4 * * *', freeze_end: '5 9 * 8 *', cron_timezone: 'America/New_York') }
  let_it_be(:freeze_period_2) { create(:ci_freeze_period, project: project, freeze_start: '0 12 * * 1-5', freeze_end: '0 1 5 * *', cron_timezone: 'Etc/UTC') }
  let_it_be(:freeze_period_3) { create(:ci_freeze_period, project: project, freeze_start: '0 12 * * 1-5', freeze_end: '0 16 * * 6', cron_timezone: 'Europe/Berlin') }

  before(:all) do
    clean_frontend_fixtures('api/freeze-periods/')
  end

  after(:all) do
    remove_repository(project)
  end

  describe API::FreezePeriods, '(JavaScript fixtures)', type: :request do
    include ApiHelpers

    it 'api/freeze-periods/freeze-periods.json' do
      get api("/projects/#{project.id}/freeze_periods", admin)

      expect(response).to be_successful
    end
  end

  describe Ci::PipelineSchedulesHelper, '(JavaScript fixtures)', type: :controler  do
    let(:response) { timezone_data.to_json }
    it 'api/freeze-periods/timezone_data.json' do
      
    end
  end
end
