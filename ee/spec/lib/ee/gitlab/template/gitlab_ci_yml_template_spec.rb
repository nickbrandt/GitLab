# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Template::GitlabCiYmlTemplate do
  subject { described_class }

  describe '.all' do
    it 'finds the Security Products templates' do
      all = subject.all.map(&:name)

      expect(all).to include('Dependency-Scanning')
    end
  end
end
