# frozen_string_literal: true

require 'spec_helper'

describe Packages::Go::ModuleFinder do
  let_it_be(:project) { create :project }
  let_it_be(:other_project) { create :project }

  describe '#execute' do
    context 'with module name equal to project name' do
      let(:finder) { described_class.new(project, base_url(project)) }

      it 'returns a module with empty path' do
        mod = finder.execute
        expect(mod).not_to be_nil
        expect(mod.path).to eq('')
      end
    end

    context 'with module name starting with project name and slash' do
      let(:finder) { described_class.new(project, base_url(project) + '/mod') }

      it 'returns a module with non-empty path' do
        mod = finder.execute
        expect(mod).not_to be_nil
        expect(mod.path).to eq('mod')
      end
    end

    context 'with a module name not equal to and not starting with project name' do
      let(:finder) { described_class.new(project, base_url(other_project)) }

      it 'returns nil' do
        expect(finder.execute).to be_nil
      end
    end
  end

  def base_url(project)
    "#{Settings.build_gitlab_go_url}/#{project.full_path}"
  end
end
