# frozen_string_literal: true
class Packages::PackageFileFinder
  attr_reader :package, :file_name, :params

  def initialize(package, file_name, params = {})
    @package = package
    @file_name = file_name
    @params = params
  end

  def execute
    package_files.last
  end

  def execute!
    package_files.last!
  end

  private

  def package_files
    files = package.package_files

    files = by_file_name(files)
    files = by_conan_file_type(files)

    files
  end

  def by_file_name(files)
    if params[:with_file_name_like]
      files.with_file_name_like(file_name)
    else
      files.with_file_name(file_name)
    end
  end

  def by_conan_file_type(files)
    return files unless params[:conan_file_type]

    files.with_conan_file_type(params[:conan_file_type])
  end
end
