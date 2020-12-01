# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::WardenSession do
  let_it_be(:user) { create :user }
  let_it_be(:another_user) { create :user }
  let_it_be(:warden_session) { { 'warden.user.user.key' => [[user.id], '$eKr3t|<3Y'] } }
  let_it_be(:warden_sessions) { { 'gitlab.warden_sessions' => { user.id => warden_session } } }
  let!(:session) { {} }

  # Define an empty default session.
  include_context 'custom session'

  shared_context 'with a warden session' do
    before do
      session.merge! warden_session
    end
  end

  shared_context 'with a saved session' do
    before do
      session.merge! warden_sessions
    end
  end

  describe '.current_user_id' do
    include_context 'with a warden session'

    subject { Gitlab::WardenSession.current_user_id }

    it { is_expected.to eq user.id }
  end

  describe '.save' do
    context 'with a warden session' do
      include_context 'with a warden session'

      it 'archives warden data' do
        described_class.save # rubocop:disable Rails/SaveBang

        expect(Gitlab::Session.current).to include warden_sessions
      end
    end

    context 'without a warden session' do
      it 'does nothing' do
        described_class.save # rubocop:disable Rails/SaveBang

        expect(Gitlab::Session.current).to be_empty
      end
    end
  end

  describe '.load' do
    include_context 'with a warden session'

    context 'with an existing user' do
      it 'loads the warden session' do
        described_class.load(user.id)

        expect(Gitlab::Session.current).to include(warden_session)
      end
    end

    context 'with an invalid user' do
      it 'does nothing' do
        expect { described_class.load(another_user.id) }
          .not_to change { Gitlab::Session.current['warden.user.user.key'] }
      end
    end
  end

  describe '.user_authorized?' do
    subject { described_class.user_authorized?(user.id) }

    context 'with a warden session' do
      include_context 'with a warden session'

      context 'previously saved' do
        include_context 'with a saved session'

        it { is_expected.to be_truthy }
      end

      context 'not previously saved' do
        it { is_expected.to be_falsey }
      end
    end

    context 'without a warden session' do
      context 'previously saved' do
        include_context 'with a saved session'

        it { is_expected.to be_truthy }
      end

      context 'not previously saved' do
        it { is_expected.to be_falsey }
      end
    end
  end

  describe '.authorized_user_ids' do
    subject { described_class.authorized_user_ids }

    context 'previously authorized' do
      include_context 'with a saved session'

      it { is_expected.to contain_exactly user.id }
    end

    context 'not previously authorized' do
      it { is_expected.to eq [] }
    end
  end

  describe '.delete' do
    include_context 'with a saved session'

    before do
      described_class.delete(user.id)
    end

    it { expect(session).to eq( { "gitlab.warden_sessions" => {} } ) }
  end
end
