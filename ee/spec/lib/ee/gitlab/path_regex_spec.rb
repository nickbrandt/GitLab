# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::PathRegex do
  describe '.container_image_regex' do
    subject { described_class.container_image_regex }

    it { is_expected.to match('gitlab-foss') }
    it { is_expected.to match('gitlab_foss') }
    it { is_expected.to match('gitlab-org/gitlab-foss') }
    it { is_expected.to match('100px.com/100px.ruby') }
    it { is_expected.not_to match('foo/bar/baz') }
    it { is_expected.not_to match('ruby:2.3.6') }
  end
end
