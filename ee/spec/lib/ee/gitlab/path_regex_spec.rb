# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::PathRegex do
  describe '.container_image_regex' do
    subject { described_class.container_image_regex }

    it { is_expected.to match('gitlab-foss') }
    it { is_expected.to match('gitlab_foss') }
    it { is_expected.to match('gitlab-org/gitlab-foss') }
    it { is_expected.to match('100px.com/100px.ruby') }

    it 'only matches at most one slash' do
      expect(subject.match('foo/bar/baz')[0]).to eq('foo/bar')
    end

    it 'does not match other non-word characters' do
      expect(subject.match('ruby:2.3.6')[0]).to eq('ruby')
    end
  end
end
