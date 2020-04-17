# frozen_string_literal: true

class Packages::GoModuleVersion
  include ::API::Helpers::Packages::Go::ModuleHelpers

  VALID_TYPES = %i[ref commit pseudo].freeze

  attr_reader :mod, :type, :ref, :commit

  delegate :major, to: :@semver, allow_nil: true
  delegate :minor, to: :@semver, allow_nil: true
  delegate :patch, to: :@semver, allow_nil: true
  delegate :prerelease, to: :@semver, allow_nil: true
  delegate :build, to: :@semver, allow_nil: true

  def initialize(mod, type, commit, name: nil, semver: nil, ref: nil)
    raise ArgumentError.new("invalid type '#{type}'") unless VALID_TYPES.include? type
    raise ArgumentError.new("mod is required") unless mod
    raise ArgumentError.new("commit is required") unless commit

    if type == :ref
      raise ArgumentError.new("ref is required") unless ref
    elsif type == :pseudo
      raise ArgumentError.new("name is required") unless name
      raise ArgumentError.new("semver is required") unless semver
    end

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

  def full_name
    "#{mod.name}@#{name || commit.sha}"
  end

  def gomod
    @gomod ||= blob_at(@mod.path + '/go.mod')
  end

  def archive
    suffix_len = @mod.path == '' ? 0 : @mod.path.length + 1

    Zip::OutputStream.write_buffer do |zip|
      files.each do |file|
        zip.put_next_entry "#{full_name}/#{file.path[suffix_len...]}"
        zip.write blob_at(file.path)
      end
    end
  end

  def files
    return @files if defined?(@files)

    sha = @commit.sha
    tree = @mod.project.repository.tree(sha, @mod.path, recursive: true).entries.filter { |e| e.file? }
    nested = tree.filter { |e| e.name == 'go.mod' && !(@mod.path == '' && e.path == 'go.mod' || e.path == @mod.path + '/go.mod') }.map { |e| e.path[0..-7] }
    @files = tree.filter { |e| !nested.any? { |n| e.path.start_with? n } }
  end

  def blob_at(path)
    return if path.nil? || path.empty?

    path = path[1..] if path.start_with? '/'

    blobs.find { |x| x.path == path }&.data
  end

  def valid?
    @mod.path_valid?(major) && @mod.gomod_valid?(gomod)
  end

  private

  def blobs
    return @blobs if defined?(@blobs)

    @blobs = @mod.project.repository.batch_blobs(files.map { |x| [@commit.sha, x.path] })
  end
end
