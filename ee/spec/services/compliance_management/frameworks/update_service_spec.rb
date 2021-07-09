# frozen_string_literal: true

require 'spec_helper'

RSpec.describe ComplianceManagement::Frameworks::UpdateService do
  let_it_be_with_refind(:namespace) { create(:namespace) }
  let_it_be_with_refind(:framework) { create(:compliance_framework, namespace: namespace) }

  let(:current_user) { namespace.owner }
  let(:params) { { color: '#000001', description: 'New Description', name: 'New Name' } }

  subject { described_class.new(framework: framework, current_user: current_user, params: params) }

  shared_examples 'a failed update request' do
    it 'does not update the compliance framework' do
      expect { subject.execute }.not_to change { framework.name }
      expect { subject.execute }.not_to change { framework.description }
      expect { subject.execute }.not_to change { framework.color }
    end

    it 'is unsuccessful' do
      expect(subject.execute.success?).to be false
    end
  end

  context 'feature is unlicensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: false)
    end

    it_behaves_like 'a failed update request'
  end

  context 'current_user is not the namespace owner' do
    let(:current_user) { create(:user) }

    it_behaves_like 'a failed update request'
  end

  context 'when feature is licensed' do
    before do
      stub_licensed_features(custom_compliance_frameworks: true)
    end

    context 'with an invalid param passed' do
      let(:params) { { color: '0001', description: '', name: 'New Name' } }

      it 'is unsuccessful' do
        expect(subject.execute.success?).to be false
      end

      it 'has appropriate errors' do
        expect(subject.execute.payload.full_messages).to contain_exactly 'Color must be a valid color code', "Description can't be blank"
      end
    end

    context 'with valid params passed' do
      it 'updates the compliance framework with valid params' do
        subject.execute

        expect(framework.name).to eq('New Name')
        expect(framework.color).to eq('#000001')
        expect(framework.description).to eq('New Description')
      end

      it 'is successful' do
        expect(subject.execute.success?).to be true
      end
    end
  end
end
