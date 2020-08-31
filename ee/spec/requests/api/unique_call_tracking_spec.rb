# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::UniqueCallTracking do
  describe 'i_compliance_audit_events_api', :clean_gitlab_redis_shared_state do
    let_it_be(:current_user) { create(:admin) }
    let_it_be(:group) { create(:group, owner_id: current_user) }
    let_it_be(:project) { create(:project) }

    before do
      project.add_user(current_user, :maintainer)
    end

    context 'after calling all audit_events APIs as a single licensed user' do
      before do
        stub_feature_flags(track_unique_visits: true)
        stub_licensed_features(admin_audit_log: true)
      end

      subject do
        travel_to 8.days.ago do
          get api('/audit_events', current_user)
          get api("/groups/#{group.id}/audit_events", current_user)
          get api("/projects/#{project.id}/audit_events", current_user)
        end
      end

      it 'tracks 3 separate events' do
        expect(Gitlab::UsageDataCounters::HLLRedisCounter).to receive(:track_event).exactly(3).times
                                                                  .with(an_instance_of(String), an_instance_of(String))

        subject
      end

      it 'reports one unique event' do
        subject

        expect(Gitlab::UsageDataCounters::HLLRedisCounter.unique_events(event_names: 'i_compliance_audit_events_api', start_date: 2.months.ago, end_date: Date.current)).to eq(1)
      end
    end
  end
end
