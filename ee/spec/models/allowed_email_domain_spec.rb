# frozen_string_literal: true

require 'spec_helper'

describe AllowedEmailDomain do
  describe 'relations' do
    it { is_expected.to belong_to(:group) }
  end

  describe 'validations' do
    it { is_expected.to validate_presence_of(:domain) }
    it { is_expected.to validate_presence_of(:group_id) }

    describe '#valid domain' do
      subject { described_class.new(group: create(:group), domain: domain) }

      context 'valid domain' do
        let(:domain) { '*@gitlab.com' }

        it 'succeeds' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'invalid domain' do
        let(:domain) { 'invalid domain' }

        it 'fails' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:domain]).to include('The domain you entered is misformatted.')
        end
      end

      context 'domain from excluded list' do
        let(:domain) { '*@hotmail.co.uk' }

        it 'fails' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:domain]).to include('The domain you entered is not allowed.')
        end
      end
    end

    describe '#allow_root_group_only' do
      subject { described_class.new(group: group, domain: '*@gitlab.com' ) }

      context 'top-level group' do
        let(:group) { create(:group) }

        it 'succeeds' do
          expect(subject.valid?).to be_truthy
        end
      end

      context 'subgroup' do
        let(:group) { create(:group, :nested) }

        it 'fails' do
          expect(subject.valid?).to be_falsey
          expect(subject.errors[:base]).to include('Allowed email domain restriction only allowed for top-level groups')
        end
      end
    end
  end
end
