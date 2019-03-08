# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Template::GitlabCiYmlTemplate do
  subject { described_class }

  describe '.all' do
    it 'finds the Security Products templates' do
      all = subject.all.map(&:name)

      expect(all).to include('Container-Scanning')
      expect(all).to include('DAST')
      expect(all).to include('Dependency-Scanning')
      expect(all).to include('License-Management')
      expect(all).to include('SAST')
    end
  end
end
