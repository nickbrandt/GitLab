# frozen_string_literal: true

require 'spec_helper'

describe Users::SignupService do
  let(:user) { create(:user, setup_for_company: true) }

  describe '#execute' do
    it 'updates the name attribute' do
      result = update_user(user, name: 'New Name')

      expect(result).to eq(status: :success)
      expect(user.reload.name).to eq('New Name')
    end

    it 'updates the role attribute' do
      result = update_user(user, role: 'development_team_lead')

      expect(result).to eq(status: :success)
      expect(user.reload.role).to eq('development_team_lead')
    end

    it 'updates the setup_for_company attribute' do
      result = update_user(user, setup_for_company: 'false')

      expect(result).to eq(status: :success)
      expect(user.reload.setup_for_company).to be_falsey
    end

    it 'returns an error result when name is missing' do
      result = {}
      expect do
        result = update_user(user, { name: '' })
      end.not_to change { user.reload.name }
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Please fill in your full name')
    end

    it 'returns an error result when role is missing' do
      result = {}
      expect do
        result = update_user(user, { role: '' })
      end.not_to change { user.reload.role }
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Please select your role')
    end

    it 'returns an error result when setup_for_company is missing' do
      result = {}
      expect do
        result = update_user(user, { setup_for_company: '' })
      end.not_to change { user.reload.setup_for_company }
      expect(result[:status]).to eq(:error)
      expect(result[:message]).to eq('Please answer "Are you setting up GitLab for a company?"')
    end

    def update_user(user, opts)
      described_class.new(user, opts.merge(user: user)).execute
    end
  end
end
