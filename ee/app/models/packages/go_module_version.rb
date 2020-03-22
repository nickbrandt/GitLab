# frozen_string_literal: true

class Packages::GoModuleVersion #< ApplicationRecord
  SEMVER_REGEX = /v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)(?:-([-.A-Z0-9]+))?(?:\+([-.A-Z0-9]+))?/i.freeze
  VERSION_SUFFIX_REGEX = /\/v([1-9]\d*)$/i.freeze

  # belongs_to :mod

  attr_reader :mod, :tag

  delegate :name, to: :tag

  def initialize(mod, tag)
    @mod = mod
    @tag = tag
  end

  def gomod
    return @gomod unless @gomod.nil?

    blob = @mod.project.repository.blob_at(tag.dereferenced_target.sha, @mod.path + '/go.mod')
    @gomod = blob ? blob.data : ''
  end

  def valid?
    m = gomod.split("\n", 2).first
    case major
    when 0, 1
      m == "module #{@mod.name}"
    else
      m == "module #{@mod.name}/v#{major}"
    end
  end

  def major
    SEMVER_REGEX.match(@tag.name)[1].to_i
  end

  def minor
    SEMVER_REGEX.match(@tag.name)[2].to_i
  end

  def patch
    SEMVER_REGEX.match(@tag.name)[3].to_i
  end

  def prerelease
    SEMVER_REGEX.match(@tag.name)[4]
  end

  def build
    SEMVER_REGEX.match(@tag.name)[5]
  end

  def files
    return @files unless @files.nil?

    sha = @tag.dereferenced_target.sha
    tree = @mod.project.repository.tree(sha, mod.path, recursive: true).entries.filter { |e| e.file? }
    nested = tree.filter { |e| e.name == 'go.mod' && !(mod.path == '' && e.path == 'go.mod' || e.path == mod.path + '/go.mod') }.map { |e| e.path[0..-7] }
    @files = tree.filter { |e| !nested.any? { |n| e.path.start_with? n } }
  end

  def blob_at(path)
    @mod.project.repository.blob_at(tag.dereferenced_target.sha, path).data
  end
end
