# frozen_string_literal: true

require 'spec_helper'

describe Packages::GoModuleVersion, type: :model do
  let_it_be(:user) { create :user }
  let_it_be(:project) { create :project_empty_repo, creator: user, path: 'my-go-lib' }
  let_it_be(:mod) { create :go_module, project: project }

  before :all do
    create :go_module_commit, :files,   project: project, tag: 'v1.0.0', files: { 'README.md' => 'Hi' }
    create :go_module_commit, :module,  project: project, tag: 'v1.0.1'
    create :go_module_commit, :package, project: project, tag: 'v1.0.2', path: 'pkg'
    create :go_module_commit, :module,  project: project, tag: 'v1.0.3', name: 'mod'
    create :go_module_commit, :files,   project: project,                files: { 'y.go' => "package a\n" }
    create :go_module_commit, :module,  project: project,                name: 'v2'
    create :go_module_commit, :files,   project: project, tag: 'v2.0.0', files: { 'v2/x.go' => "package a\n" }
  end

  describe '#name' do
    context 'with ref and name specified' do
      let_it_be(:version) { create :go_module_version, mod: mod, name: 'foobar', commit: project.repository.head_commit, ref: project.repository.find_tag('v1.0.0') }
      it('returns that name') { expect(version.name).to eq('foobar') }
    end

    context 'with ref specified and name unspecified' do
      let_it_be(:version) { create :go_module_version, mod: mod, commit: project.repository.head_commit, ref: project.repository.find_tag('v1.0.0') }
      it('returns the name of the ref') { expect(version.name).to eq('v1.0.0') }
    end

    context 'with ref and name unspecified' do
      let_it_be(:version) { create :go_module_version, mod: mod, commit: project.repository.head_commit }
      it('returns nil') { expect(version.name).to eq(nil) }
    end
  end

  describe '#gomod' do
    context 'with go.mod missing' do
      let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.0' }
      it('returns nil') { expect(version.gomod).to eq(nil) }
    end

    context 'with go.mod present' do
      let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.1' }
      it('returns the contents of go.mod') { expect(version.gomod).to eq("module #{mod.name}\n") }
    end
  end

  describe '#files' do
    context 'with a root module' do
      context 'with an empty module path' do
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.2' }
        it('returns all the files') { expect(version.files.map { |x| x.path }.to_set).to eq(Set['README.md', 'go.mod', 'a.go', 'pkg/b.go']) }
      end
    end

    context 'with a root module and a submodule' do
      context 'with an empty module path' do
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.3' }
        it('returns files excluding the submodule') { expect(version.files.map { |x| x.path }.to_set).to eq(Set['README.md', 'go.mod', 'a.go', 'pkg/b.go']) }
      end

      context 'with the submodule\'s path' do
        let_it_be(:mod) { create :go_module, project: project, path: 'mod' }
        let_it_be(:version) { create :go_module_version, :tagged, mod: mod, name: 'v1.0.3' }
        it('returns the submodule\'s files') { expect(version.files.map { |x| x.path }.to_set).to eq(Set['mod/go.mod', 'mod/a.go']) }
      end
    end
  end
end
