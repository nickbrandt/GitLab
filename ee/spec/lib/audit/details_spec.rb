# frozen_string_literal: true

require 'spec_helper'

describe Audit::Details do
  let(:user) { create(:user) }

  describe '.humanize' do
    context 'user' do
      let(:login_action) do
        {
          with: :ldap,
          target_id: user.id,
          target_type: 'User',
          target_details: user.name
        }
      end

      it 'humanizes user login action' do
        string = described_class.humanize(login_action)

        expect(string).to eq('Signed in with LDAP authentication')
      end
    end

    context 'project' do
      let(:user_member) { create(:user) }
      let(:project) { create(:project) }
      let(:member) { create(:project_member, :developer, user: user_member, project: project) }
      let(:member_access_action) do
        {
          add: 'user_access',
          as: Gitlab::Access.options_with_owner.key(member.access_level.to_i),
          author_name: user.name,
          target_id: member.id,
          target_type: 'User',
          target_details: member.user.name
        }
      end

      it 'humanizes add project member access action' do
        string = described_class.humanize(member_access_action)

        expect(string).to eq('Added user access as Developer')
      end
    end

    context 'group' do
      let(:user_member) { create(:user) }
      let(:group) { create(:group) }
      let(:member) { create(:group_member, group: group, user: user_member) }
      let(:target_type) { 'User' }
      let(:member_access_action) do
        {
          change: 'access_level',
          from: 'Guest',
          to: member.human_access,
          author_name: user.name,
          target_id: member.id,
          target_type: target_type,
          target_details: member.user.name
        }
      end

      context 'when the target_type is not Operations::FeatureFlag' do
        it 'humanizes add group member access action' do
          string = described_class.humanize(member_access_action)

          expect(string).to eq('Changed access level from Guest to Owner')
        end
      end
    end

    context 'failed_login' do
      let(:feature_flag) do
        {
          failed_login: 'google_oauth2',
          author_name: 'username',
          target_details: 'testuser',
          ip_address: '127.0.0.1'
        }
      end
      let(:message) { 'Failed to login with GOOGLE authentication' }

      it 'shows the correct failed login meessage' do
        string = described_class.humanize(feature_flag)

        expect(string).to eq message
      end
    end

    context 'deploy key' do
      let(:removal_action) do
        {
          remove: 'deploy_key',
          author_name: user.name,
          target_id: 'key title',
          target_type: 'DeployKey',
          target_details: 'key title'
        }
      end

      it 'humanizes the removal action' do
        string = described_class.humanize(removal_action)

        expect(string).to eq('Removed deploy key')
      end
    end

    context 'change email' do
      let(:action) do
        {
            change: 'email',
            from: 'a@b.com',
            to: 'c@b.com',
            author_name: 'author',
            target_id: '',
            target_type: 'Email',
            target_details: 'Email'
        }
      end

      it 'humanizes the removal action' do
        string = described_class.humanize(action)

        expect(string).to eq('Changed email from a@b.com to c@b.com')
      end
    end

    context 'updated ref' do
      let(:action) do
        {
          updated_ref: 'master',
          author_name: 'Hackerman',
          from: 'b6bce79c',
          to: 'a7bce79c',
          target_details: 'group/project'
        }
      end

      it 'humanizes the action' do
        string = described_class.humanize(action)

        expect(string).to eq('Updated ref master from b6bce79c to a7bce79c')
      end
    end

    context 'system event' do
      let(:user_member) { create(:user) }
      let(:project) { create(:project) }
      let(:member) { create(:project_member, :developer, user: user_member, project: project, expires_at: 1.day.from_now) }
      let(:system_event_action) do
        {
          remove: 'user_access',
          author_name: 'Admin User',
          target_id: member.id,
          target_type: 'User',
          target_details: member.user.name,
          system_event: true,
          reason: "access expired on #{member.expires_at}"
        }
      end

      it 'humanizes system event' do
        string = described_class.humanize(system_event_action)

        expect(string).to eq("Removed user access via system job. Reason: access expired on #{member.expires_at}")
      end
    end
  end
end
