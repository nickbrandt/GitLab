# frozen_string_literal: true
require 'spec_helper'

RSpec.describe Gitlab::HookData::UserBuilder do
  let_it_be(:user) { create(:user, name: 'John Doe', username: 'johndoe', email: 'john@example.com') }

  describe '#build' do
    let(:event) { :create }
    let(:data) { described_class.new(user).build(event) }

    context 'data' do
      context 'email_opted_in_data attributes' do
        let(:user) { create(:group_with_plan, plan: :ultimate_plan) }

        it 'returns correct group_plan' do
          expect(data).to include(:group_plan)
          expect(data[:group_plan]).to eq('ultimate')
        end
      end
    end
  end
end
