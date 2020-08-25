# frozen_string_literal: true

require 'spec_helper'

RSpec.describe API::GroupPushRule, 'GroupPushRule', api: true do
  include ApiHelpers
  include AccessMatchersForRequest

  let_it_be(:admin) { create(:user, :admin) }
  let_it_be(:user) { create(:user) }

  shared_examples 'not found when feature is unavailable' do
    before do
      stub_licensed_features(push_rules: false)
    end

    it do
      subject

      expect(response).to have_gitlab_http_status(:not_found)
    end
  end

  shared_examples 'allow access to api based on role' do
    it { expect { subject }.to be_allowed_for(:admin) }
    it { expect { subject }.to be_allowed_for(:owner).of(group) }

    it { expect { subject }.to be_denied_for(:developer).of(group) }
    it { expect { subject }.to be_denied_for(:reporter).of(group) }
    it { expect { subject }.to be_denied_for(:guest).of(group) }
    it { expect { subject }.to be_denied_for(:anonymous) }
  end

  describe 'GET /groups/:id/push_rule' do
    let_it_be(:group) { create(:group) }
    let_it_be(:attributes) do
      {
        author_email_regex: '^[A-Za-z0-9.]+@gitlab.com$',
        commit_committer_check: true,
        commit_message_negative_regex: '[x+]',
        commit_message_regex: '[a-zA-Z]',
        deny_delete_tag: false,
        max_file_size: 100,
        member_check: false,
        prevent_secrets: true,
        reject_unsigned_commits: true
      }
    end

    before_all do
      push_rule = create(:push_rule, **attributes)
      group.update!(push_rule: push_rule)
    end

    context 'when unlicensed' do
      subject { get api("/groups/#{group.id}/push_rule", admin) }

      it_behaves_like 'not found when feature is unavailable'
    end

    context 'authorized user' do
      subject { get api("/groups/#{group.id}/push_rule", admin) }

      context 'when licensed' do
        before do
          stub_licensed_features(push_rules: true,
                                 commit_committer_check: true,
                                 reject_unsigned_commits: true)
        end

        it 'returns attributes as expected' do
          subject

          expect(json_response).to eq(
            {
             "author_email_regex" => attributes[:author_email_regex],
             "branch_name_regex" => nil,
             "commit_committer_check" => true,
             "commit_message_negative_regex" => attributes[:commit_message_negative_regex],
             "commit_message_regex" => attributes[:commit_message_regex],
             "created_at" => group.push_rule.created_at.iso8601(3),
             "deny_delete_tag" => false,
             "file_name_regex" => nil,
             "id" => group.push_rule.id,
             "max_file_size" => 100,
             "member_check" => false,
             "prevent_secrets" => true,
             "reject_unsigned_commits" => true
            }
          )
        end

        it 'matches response schema' do
          subject

          expect(response).to match_response_schema('entities/group_push_rules')
        end
      end

      context 'when reject_unsigned_commits is unavailable' do
        before do
          stub_licensed_features(reject_unsigned_commits: false)
        end

        it do
          subject

          expect(json_response).not_to have_key('reject_unsigned_commits')
        end
      end

      context 'when commit_committer_check is unavailable' do
        before do
          stub_licensed_features(commit_committer_check: false)
        end

        it do
          subject

          expect(json_response).not_to have_key('commit_committer_check')
        end
      end
    end

    context 'permissions' do
      subject(:get_push_rules) { get api("/groups/#{group.id}/push_rule", user) }

      it_behaves_like 'allow access to api based on role'
    end

    context 'when push rule does not exist' do
      let_it_be(:no_push_rule_group) { create(:group) }

      it 'returns not found' do
        get api("/groups/#{no_push_rule_group.id}/push_rule", admin)

        expect(response).to have_gitlab_http_status(:not_found)
      end
    end
  end
end
