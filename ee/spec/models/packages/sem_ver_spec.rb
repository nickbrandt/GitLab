# frozen_string_literal: true

require 'fast_spec_helper'

RSpec.describe Packages::SemVer, type: :model do
  shared_examples '#parse with a valid semver' do |str, major, minor, patch, prerelease, build|
    subject(:semver) { described_class.new(major, minor, patch, prerelease, build) }

    context "with #{str}" do
      subject(:expected) { semver.with(prefixed: prefixed) }

      context 'prefixed' do
        let(:prefixed) { true }

        specify do
          expect(described_class.parse('v' + str, prefixed: true)).to eq(expected)
        end
      end

      context 'without prefix' do
        let(:prefixed) { false }

        specify do
          expect(described_class.parse(str)).to eq(expected)
        end
      end
    end
  end

  shared_examples '#parse with an invalid semver' do |str|
    context "with #{str}" do
      it 'returns nil with prefix' do
        expect(described_class.parse('v' + str, prefixed: true)).to be_nil
      end

      it 'returns nil without prefix' do
        expect(described_class.parse(str)).to be_nil
      end
    end
  end

  shared_examples 'sorted' do
    it 'orders correctly' do
      (1..10).each do |_|
        expect(expected_list.shuffle.sort.map(&:to_s)).to eq(expected_list.map(&:to_s))
      end
    end
  end

  describe '#parse' do
    it_behaves_like '#parse with a valid semver', '1.0.0', 1, 0, 0, nil, nil
    it_behaves_like '#parse with a valid semver', '1.0.0-pre', 1, 0, 0, 'pre'
    it_behaves_like '#parse with a valid semver', '1.0.0+build', 1, 0, 0, nil, 'build'
    it_behaves_like '#parse with a valid semver', '1.0.0-pre+build', 1, 0, 0, 'pre', 'build'
    it_behaves_like '#parse with an invalid semver', '01.0.0'
    it_behaves_like '#parse with an invalid semver', '0.01.0'
    it_behaves_like '#parse with an invalid semver', '0.0.01'
    it_behaves_like '#parse with an invalid semver', '1.0.0asdf'
  end

  describe '#<=>' do
    let(:v1) { described_class.new(1, 0, 0) }
    let(:v2) { described_class.new(2, 0, 0) }

    it_behaves_like 'sorted' do
      let(:expected_list) { [v1.with(pre: 'beta'), v1, v1.with(minor: 1), v2.with(pre: 'alpha'), v2, v2.with(patch: 1), v2.with(minor: 1)] }
    end

    it_behaves_like 'sorted' do
      let(:expected_list) { [v1.with(pre: 'alpha'), v1.with(pre: 'alpha.1'), v1.with(pre: 'alpha.beta'), v1.with(pre: 'beta'), v1.with(pre: 'beta.2'), v1.with(pre: 'beta.11'), v1.with(pre: 'rc.1'), v1] }
    end
  end
end
