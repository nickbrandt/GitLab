# frozen_string_literal: true

require 'spec_helper'

describe API::Members do
  let(:user) { create(:user) }

  describe 'POST /projects/:id/members' do
    context 'group membership locked' do
      let(:owner) { create(:user) }
      let(:group) { create(:group, membership_lock: true)}
      let(:project) { create(:project, group: group) }

      before do
        group.add_owner(owner)
      end

      context 'project in a group' do
        it 'returns a 405 method not allowed error when group membership lock is enabled' do
          post api("/projects/#{project.id}/members", owner),
               params: { user_id: user.id, access_level: Member::MAINTAINER }

          expect(response.status).to eq 405
        end
      end
    end
  end
end
