# frozen_string_literal: true

require 'spec_helper'

shared_examples_for 'has user mentions' do
  describe '#has_mentions?' do
    context 'when no mentions' do
      it 'returns false' do
        expect(subject.mentioned_users_ids).to be nil
        expect(subject.mentioned_projects_ids).to be nil
        expect(subject.mentioned_groups_ids).to be nil
        expect(subject.has_mentions?).to be false
      end
    end

    context 'when mentioned_users_ids not null' do
      let!(:mentioned_user) { create(:user) }
      let(:last_id) { User.last&.id.to_i }

      context 'when mentioned users do not exist' do
        subject { described_class.new(mentioned_users_ids: [last_id + 10, last_id + 15]) }

        it 'returns false' do
          expect(subject.has_mentions?).to be false
        end
      end

      context 'when at least one mentioned user exists' do
        subject { described_class.new(mentioned_users_ids: [mentioned_user.id, last_id + 10, 3]) }

        it 'returns true' do
          expect(subject.has_mentions?).to be true
        end
      end
    end

    context 'when mentioned projects' do
      let!(:mentioned_project) { create(:project) }
      let(:last_id) { Project.last&.id.to_i }

      context 'when mentioned projects do not exist' do
        subject { described_class.new(mentioned_projects_ids: [last_id + 10, last_id + 15]) }

        it 'returns false' do
          expect(subject.has_mentions?).to be false
        end
      end

      context 'when mentioned projects exist' do
        subject { described_class.new(mentioned_projects_ids: [mentioned_project.id, last_id + 10]) }

        it 'returns true' do
          expect(subject.has_mentions?).to be true
        end
      end
    end

    context 'when mentioned groups' do
      let!(:mentioned_group) { create(:group) }
      let(:last_id) { Group.last&.id.to_i }

      context 'when mentioned groups do not exist' do
        subject { described_class.new(mentioned_groups_ids: [last_id + 10, last_id + 15]) }

        it 'returns false' do
          expect(subject.has_mentions?).to be false
        end
      end

      context 'when mentioned groups exist' do
        subject { described_class.new(mentioned_groups_ids: [mentioned_group.id, last_id + 10]) }

        it 'returns true' do
          expect(subject.has_mentions?).to be true
        end
      end
    end
  end
end
