# frozen_string_literal: true
require 'spec_helper'

describe Packages::NpmPackagesFinder do
  let(:package) { create(:npm_package) }
  let(:project) { package.project }

  describe '#execute!' do
    it 'returns project packages' do
      finder = described_class.new(project, package.name)

      expect(finder.execute).to eq([package])
    end

    it 'returns an empty collection' do
      finder = described_class.new(project, 'baz')

      expect(finder.execute).to be_empty
    end
  end
end
