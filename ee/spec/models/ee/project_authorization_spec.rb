# frozen_string_literal: true

require 'spec_helper'

describe ProjectAuthorization do
  describe '.roles_stats' do
    before do
      project1 = create(:project_empty_repo)
      project1.add_reporter(create(:user))

      project2 = create(:project_empty_repo)
      project2.add_developer(create(:user))

      # Add same user as Reporter and Developer to different projects
      # and expect it to be counted once for the stats
      user = create(:user)
      project1.add_reporter(user)
      project2.add_developer(user)
    end

    subject { described_class.roles_stats.to_a }

    it do
      expect(amount_for_kind('reporter')).to eq(1)
      expect(amount_for_kind('developer')).to eq(2)
      expect(amount_for_kind('maintainer')).to eq(2)
    end

    def amount_for_kind(access_level)
      subject.find do |row|
        row['kind'] == access_level
      end['amount'].to_i
    end
  end

  describe '.visible_to_user_and_access_level' do
    let(:user) { create(:user) }
    let(:project1) { create(:project) }
    let(:project2) { create(:project) }

    it 'returns the records for given user that have at least the given access' do
      described_class.create!(user: user, project: project2, access_level: Gitlab::Access::DEVELOPER)
      maintainer_access = described_class.create!(user: user, project: project1, access_level: Gitlab::Access::MAINTAINER)

      authorizations = described_class.visible_to_user_and_access_level(user, Gitlab::Access::MAINTAINER)

      expect(authorizations.count).to eq(1)
      expect(authorizations[0].user_id).to eq(maintainer_access.user_id)
      expect(authorizations[0].project_id).to eq(maintainer_access.project_id)
      expect(authorizations[0].access_level).to eq(maintainer_access.access_level)
    end
  end
end
