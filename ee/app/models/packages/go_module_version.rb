# frozen_string_literal: true

class Packages::GoModuleVersion
  include ::API::Helpers::Packages::Go::ModuleHelpers

  attr_reader :mod, :type, :ref, :commit

  delegate :major, to: :@semver, allow_nil: true
  delegate :minor, to: :@semver, allow_nil: true
  delegate :patch, to: :@semver, allow_nil: true
  delegate :prerelease, to: :@semver, allow_nil: true
  delegate :build, to: :@semver, allow_nil: true

  def initialize(mod, type, commit, name: nil, semver: nil, ref: nil)
    @mod = mod
    @type = type
    @commit = commit
    @name = name if name
    @semver = semver if semver
    @ref = ref if ref
  end

  def name
    @name || @ref&.name
  end

  def gomod
    @gomod ||= blob_at(@mod.path + '/go.mod')
  end

  def files
    return @files if defined?(@files)

    sha = @commit.sha
    tree = @mod.project.repository.tree(sha, @mod.path, recursive: true).entries.filter { |e| e.file? }
    nested = tree.filter { |e| e.name == 'go.mod' && !(@mod.path == '' && e.path == 'go.mod' || e.path == @mod.path + '/go.mod') }.map { |e| e.path[0..-7] }
    @files = tree.filter { |e| !nested.any? { |n| e.path.start_with? n } }
  end

  def blob_at(path)
    @mod.project.repository.blob_at(@commit.sha, path)&.data
  end

  def valid?
    @mod.path_valid?(major) && @mod.gomod_valid?(gomod)
  end
end
