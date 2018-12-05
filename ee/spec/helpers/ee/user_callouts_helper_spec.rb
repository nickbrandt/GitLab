# frozen_string_literal: true

require 'spec_helper'

describe EE::UserCalloutsHelper do
  let(:user) { create(:user) }

  before do
    allow(helper).to receive(:current_user).and_return(user)
  end

  describe '.show_gold_trial?' do
    let(:suitable_env) { nil }

    before do
      allow(helper).to receive(:user_dismissed?).with(described_class::GOLD_TRIAL).and_return(user_dismissed)
      allow(helper).to receive(:show_gold_trial_suitable_env?).and_return(suitable_env)
    end

    context 'when user has already dismissed the callout' do
      let(:user_dismissed) { true }

      it 'returns false' do
        expect(helper.show_gold_trial?).to be_falsey
      end
    end

    context 'when show_gold_trial_suitable_env? returns false' do
      let(:user_dismissed) { false }
      let(:suitable_env) { false }

      it 'returns false' do
        expect(helper.show_gold_trial?).to be_falsey
      end
    end

    context 'when show_gold_trial_namespaces_checked?' do
      let(:user_dismissed) { false }
      let(:suitable_env) { true }

      before do
        allow(helper).to receive(:users_namespaces_clean?).and_return(namespaces_checked)
      end

      context 'returns false' do
        let(:namespaces_checked) { false }

        it 'returns false' do
          expect(helper.show_gold_trial?).to be_falsey
        end
      end

      context 'returns true' do
        let(:namespaces_checked) { true }

        it 'returns true' do
          expect(helper.show_gold_trial?).to be_truthy
        end
      end
    end
  end

  describe '.show_gold_trial_suitable_env?' do
    before do
      allow(Gitlab).to receive(:com?).and_return(gitlab_com)
      allow(Rails.env).to receive(:development?).and_return(rails_dev_env)
      allow(Gitlab::Database).to receive(:read_only?).and_return(db_read_only)
    end

    context 'with a writable DB' do
      let(:db_read_only) { false }

      context "when we're neither GitLab.com or a Rails development env" do
        let(:gitlab_com) { false }
        let(:rails_dev_env) { false }

        it 'returns true' do
          expect(helper.show_gold_trial_suitable_env?).to be_falsey
        end
      end

      context "when we're GitLab.com" do
        let(:gitlab_com) { true }
        let(:rails_dev_env) { false }

        it 'returns true' do
          expect(helper.show_gold_trial_suitable_env?).to be_truthy
        end
      end

      context "when we're a Rails development env" do
        let(:gitlab_com) { false }
        let(:rails_dev_env) { true }

        it 'returns true' do
          expect(helper.show_gold_trial_suitable_env?).to be_truthy
        end
      end
    end

    context 'with a readonly DB' do
      let(:db_read_only) { true }

      context "when we're GitLab.com" do
        let(:gitlab_com) { true }
        let(:rails_dev_env) { false }

        it 'returns true' do
          expect(helper.show_gold_trial_suitable_env?).to be_falsey
        end
      end

      context "when we're a Rails development env" do
        let(:gitlab_com) { false }
        let(:rails_dev_env) { true }

        it 'returns true' do
          expect(helper.show_gold_trial_suitable_env?).to be_falsey
        end
      end
    end
  end

  describe '.show_gold_trial_namespaces_checked?' do
    let(:a_name_space_has_trial) { nil }

    before do
      allow(user).to receive(:any_namespace_with_gold?).and_return(a_name_space_has_gold)
      allow(user).to receive(:any_namespace_with_trial?).and_return(a_name_space_has_trial)
    end

    context "when a user's namespace has gold" do
      let(:a_name_space_has_gold) { true }

      it 'returns false' do
        expect(helper.users_namespaces_clean?(user)).to be_falsey
      end
    end

    context "when a user's namespace does not have gold" do
      let(:a_name_space_has_gold) { false }

      context "but a user's namespace has a trial" do
        let(:a_name_space_has_trial) { true }

        it 'returns false' do
          expect(helper.users_namespaces_clean?(user)).to be_falsey
        end
      end

      context "and does not have a trial" do
        let(:a_name_space_has_trial) { false }

        it 'returns true' do
          expect(helper.users_namespaces_clean?(user)).to be_truthy
        end
      end
    end
  end
end
