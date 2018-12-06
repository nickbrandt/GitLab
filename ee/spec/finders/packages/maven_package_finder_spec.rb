# frozen_string_literal: true
require 'spec_helper'

describe Packages::MavenPackageFinder do
  let(:project) { create(:project) }
  let(:package) { create(:maven_package, project: project) }

  describe '#execute!' do
    context 'within the project' do
      it 'returns a package' do
        finder = described_class.new(package.maven_metadatum.path, project)

        expect(finder.execute!).to eq(package)
      end

      it 'raises an error' do
        finder = described_class.new('com/example/my-app/1.0-SNAPSHOT', project)

        expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end

    context 'across all projects' do
      it 'returns a package' do
        finder = described_class.new(package.maven_metadatum.path)

        expect(finder.execute!).to eq(package)
      end

      it 'raises an error' do
        finder = described_class.new('com/example/my-app/1.0-SNAPSHOT')

        expect { finder.execute! }.to raise_error(ActiveRecord::RecordNotFound)
      end
    end
  end
end
