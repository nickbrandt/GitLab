# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Monitor::DemoProjects do
  describe '#oids' do
    subject { described_class.oids }

    it 'fetches oids when in test env' do
      project = create(:project)

      expect(subject).to eq([project.id])
    end

    it 'fetches oids when on gitlab.com' do
      expect(Gitlab).to receive(:'com?').and_return(true)

      expect(subject).to eq(Gitlab::Monitor::DemoProjects::DOT_COM_IDS)
    end

    it 'fetches oids when on staging' do
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
