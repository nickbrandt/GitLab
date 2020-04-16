# frozen_string_literal: true

require 'spec_helper'

describe Ci::Minutes::Context do
  let_it_be(:group) { create(:group) }
  let(:project) { build(:project, namespace: group) }

  shared_examples 'full path' do
    describe '#full_path' do
      it 'shows full path' do
        expect(subject.full_path).to eq context.full_path
      end
    end

    describe '#level' do
      it 'assigns correct level of namespace or project' do
        expect(subject.level).to eq context
      end
    end
  end

  shared_examples 'captures root namespace' do
    describe '#namespace' do
      it 'assigns the namespace' do
        expect(subject.namespace).to eq group
      end
    end
  end

  context 'when at project level' do
    subject { described_class.new(project, nil) }

    it_behaves_like 'captures root namespace'

    it_behaves_like 'full path' do
      let(:context) { project }
    end
  end

  context 'when at namespace level' do
    subject { described_class.new(nil, group) }

    it_behaves_like 'captures root namespace'

    it_behaves_like 'full path' do
      let(:context) { group }
    end
  end
end
