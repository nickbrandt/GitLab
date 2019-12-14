# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Regex do
  describe '.conan_file_name_regex' do
    subject { described_class.conan_file_name_regex }

    it { is_expected.to match('conanfile.py') }
    it { is_expected.to match('conan_package.tgz') }
    it { is_expected.not_to match('foo.txt') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.conan_package_reference_regex' do
    subject { described_class.conan_package_reference_regex }

    it { is_expected.to match('123456789') }
    it { is_expected.to match('asdf1234') }
    it { is_expected.not_to match('@foo') }
    it { is_expected.not_to match('0/pack+age/1@1/0') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.conan_revision_regex' do
    subject { described_class.conan_revision_regex }

    it { is_expected.to match('0') }
    it { is_expected.not_to match('foo') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.conan_recipe_component_regex' do
    subject { described_class.conan_recipe_component_regex }

    it { is_expected.to match('foobar') }
    it { is_expected.to match('foo_bar') }
    it { is_expected.to match('foo+bar') }
    it { is_expected.to match('1.0.0') }
    it { is_expected.not_to match('foo@bar') }
    it { is_expected.not_to match('foo/bar') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.feature_flag_regex' do
    subject { described_class.feature_flag_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('f_feature_flag') }
    it { is_expected.not_to match('MY_FEATURE_FLAG') }
    it { is_expected.not_to match('my feature flag') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.package_name_regex' do
    subject { described_class.package_name_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo/bar') }
    it { is_expected.to match('@foo/bar') }
    it { is_expected.to match('com/mycompany/app/my-app') }
    it { is_expected.to match('my-package/1.0.0@my+project+path/beta') }
    it { is_expected.not_to match('my-package/1.0.0@@@@@my+project+path/beta') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('@foo/@/bar') }
    it { is_expected.not_to match('@@foo/bar') }
    it { is_expected.not_to match('my package name') }
    it { is_expected.not_to match('!!()()') }
    it { is_expected.not_to match("..\n..\foo") }
  end

  describe '.maven_file_name_regex' do
    subject { described_class.maven_file_name_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo+bar-2_0.pom') }
    it { is_expected.to match('foo.bar.baz-2.0-20190901.47283-1.jar') }
    it { is_expected.to match('maven-metadata.xml') }
    it { is_expected.to match('1.0-SNAPSHOT') }
    it { is_expected.not_to match('../../foo') }
    it { is_expected.not_to match('..\..\foo') }
    it { is_expected.not_to match('%2f%2e%2e%2f%2essh%2fauthorized_keys') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('my file name') }
    it { is_expected.not_to match('!!()()') }
  end

  describe '.maven_path_regex' do
    subject { described_class.maven_path_regex }

    it { is_expected.to match('123') }
    it { is_expected.to match('foo') }
    it { is_expected.to match('foo/bar') }
    it { is_expected.to match('@foo/bar') }
    it { is_expected.to match('com/mycompany/app/my-app') }
    it { is_expected.to match('com/mycompany/app/my-app/1.0-SNAPSHOT') }
    it { is_expected.to match('com/mycompany/app/my-app/1.0-SNAPSHOT+debian64') }
    it { is_expected.not_to match('com/mycompany/app/my+app/1.0-SNAPSHOT') }
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('@foo/@/bar') }
    it { is_expected.not_to match('my package name') }
    it { is_expected.not_to match('!!()()') }
  end
end
