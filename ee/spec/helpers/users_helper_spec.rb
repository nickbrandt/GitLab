# frozen_string_literal: true

require 'spec_helper'

describe UsersHelper do
  describe '#current_user_menu_items' do
    let(:user) { create(:user) }
    using RSpec::Parameterized::TableSyntax

    where(
      has_paid_namespace?: [true, false],
      user?: [true, false],
      gitlab_com?: [true, false],
      user_eligible?: [true, false]
    )

    with_them do
      before do
        allow(helper).to receive(:current_user) { user? ? user : nil }
        allow(helper).to receive(:can?).and_return(false)

        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(user).to receive(:any_namespace_without_trial?) { user_eligible? }
        allow(user).to receive(:has_paid_namespace?) { has_paid_namespace? }
      end

      let(:expected_result) { !has_paid_namespace? && user? && gitlab_com? && user_eligible? }

      subject { helper.current_user_menu_items.include?(:start_trial) }

      it { is_expected.to eq(expected_result) }
    end
  end
end
