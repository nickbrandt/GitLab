# frozen_string_literal: true

require 'spec_helper'

describe UsersHelper do
  describe '#current_user_menu_items' do
    let(:user) { create(:user) }
    using RSpec::Parameterized::TableSyntax

    subject(:items) { helper.current_user_menu_items }

    where(:user?, :gitlab_com?, :user_eligible?, :should_include_start_trial?) do
      true  | true   | true   | true
      true  | true   | false  | false
      true  | false  | true   | false
      true  | false  | false  | false
      false | true   | true   | false
      false | true   | false  | false
      false | false  | true   | false
      false | false  | false  | false
    end

    with_them do
      before do
        allow(helper).to receive(:current_user) { user? ? user : nil }
        allow(helper).to receive(:can?).and_return(false)

        allow(::Gitlab).to receive(:com?) { gitlab_com? }
        allow(user).to receive(:any_namespace_without_trial?) { user_eligible? }
      end

      it do
        if should_include_start_trial?
          expect(items).to include(:start_trial)
        else
          expect(items).not_to include(:start_trial)
        end
      end
    end
  end
end
