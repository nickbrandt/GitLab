# frozen_string_literal: true
require 'spec_helper'

describe IdentityProviderPolicy do
  subject(:policy) { described_class.new(user, :a_provider) }

  describe '#rules' do
    context 'when user is group managed' do
      let(:user) { build_stubbed(:user, :group_managed) }

      it { is_expected.not_to be_allowed(:link) }
      it { is_expected.not_to be_allowed(:unlink) }
    end
  end
end
