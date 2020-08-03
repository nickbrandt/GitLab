# frozen_string_literal: true

require 'spec_helper'

RSpec.describe 'Freeze Periods (JavaScript fixtures)' do
  include JavaScriptFixturesHelpers

  let_it_be(:admin) { create(:admin) }
  let_it_be(:project) { create(:project, :repository, path: 'freeze-periods-project') }
  let_it_be(:freeze_period) { create(:ci_freeze_period, project: project, created_at: 2.days.ago) }

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
end
