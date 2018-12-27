# coding: utf-8
require 'spec_helper'

describe Gitlab::Regex do
  describe '.environment_scope_regex' do
    subject { described_class.environment_scope_regex }

    it { is_expected.to match('foo') }
    it { is_expected.to match('foo*Z') }
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
    it { is_expected.not_to match('$foo/bar') }
    it { is_expected.not_to match('@foo/@/bar') }
    it { is_expected.not_to match('my package name') }
    it { is_expected.not_to match('!!()()') }
  end
end
