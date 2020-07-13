# frozen_string_literal: true

require 'spec_helper'

RSpec.describe DastSiteProfiles::CreateService do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository, creator: user) }
  let(:name) { FFaker::Company.catch_phrase }
  let(:target_url) { FFaker::Internet.uri(:http) }

  describe '#execute' do
    subject { described_class.new(project, user).execute(name: name, target_url: target_url) }

    let(:status) { subject.status }
    let(:message) { subject.message }

    context 'when the user does not have permission to run a dast scan' do
      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('Insufficient permissions')
      end
    end

    context 'when the user can run a dast scan' do
      before do
        project.add_developer(user)
      end

      it 'returns an error status' do
        expect(status).to eq(:error)
      end

      it 'populates message' do
        expect(message).to eq('Not implemented')
      end
    end
  end
end
