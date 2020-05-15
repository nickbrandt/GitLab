# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Monitor::DemoProjects do
  describe '#primary_keys' do
    subject { described_class.primary_keys }

    it 'fetches primary_keys when in test env' do
      project = create(:project)

      expect(subject).to eq([project.id])
    end

    it 'fetches primary_keys when on gitlab.com' do
      expect(Gitlab).to receive(:'com?').and_return(true)

      expect(subject).to eq(Gitlab::Monitor::DemoProjects::DOT_COM_IDS)
    end

    it 'fetches primary_keys when on staging' do
      expect(Gitlab).to receive(:staging?).and_return(true)

      expect(subject).to eq(Gitlab::Monitor::DemoProjects::STAGING_IDS)
    end

    it 'falls back on empty array' do
      stub_config_setting(url: 'https://helloworld')
      expect(Rails).to receive(:env).and_return(
        double(development?: false, test?: false)
      ).twice

      expect(subject).to eq([])
    end
  end
end
