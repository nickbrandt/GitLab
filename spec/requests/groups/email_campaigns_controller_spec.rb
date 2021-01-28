# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Groups::EmailCampaignsController do
  include InProductMarketingHelper
  using RSpec::Parameterized::TableSyntax

  describe 'GET #index', :snowplow do
    let_it_be(:group) { create(:group) }
    let_it_be(:project) { create(:project, group: group) }
    let_it_be(:user) { create(:user) }
    let(:track) { 'create' }
    let(:series) { '0' }

    before do
      sign_in(user)
      group.add_developer(user)
      allow(Gitlab::Tracking).to receive(:self_describing_event)
    end

    subject(:get_index) do
      get group_email_campaigns_url(group, track: track, series: series)
      response
    end

    RSpec::Matchers.define :track_event do |*args|
      match do
        expect(Gitlab::Tracking).to have_received(:self_describing_event).with(
          described_class::EMAIL_CAMPAIGNS_SCHEMA_URL,
          data: {
            namespace_id: group.id,
            track: track.to_sym,
            series: series.to_i,
            subject_line: subject_line(track.to_sym, series.to_i)
          }
        )
      end

      match_when_negated do
        expect(Gitlab::Tracking).not_to have_received(:self_describing_event)
      end
    end

    context 'track parameter' do
      where(:track, :valid) do
        'create' | true
        'verify' | true
        'trial'  | true
        'team'   | true
        'xxxx'   | false
        nil      | false
      end

      with_them do
        it do
          if valid
            is_expected.to track_event
            is_expected.to have_gitlab_http_status(:redirect)
          else
            is_expected.not_to track_event
            is_expected.to have_gitlab_http_status(:not_found)
          end
        end
      end
    end

    context 'series parameter' do
      where(:series, :valid) do
        '0'  | true
        '1'  | true
        '2'  | true
        '-1' | false
        '3'  | false
        nil  | false
      end

      with_them do
        it do
          if valid
            is_expected.to track_event
            is_expected.to have_gitlab_http_status(:redirect)
          else
            is_expected.not_to track_event
            is_expected.to have_gitlab_http_status(:not_found)
          end
        end
      end
    end
  end
end
