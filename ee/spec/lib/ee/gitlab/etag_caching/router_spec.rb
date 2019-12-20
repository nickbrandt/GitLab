# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::EtagCaching::Router do
  it 'matches epic notes endpoint' do
    result = described_class.match(
      '/groups/my-group/and-subgroup/-/epics/1/notes'
    )

    expect(result).to be_present
    expect(result.name).to eq 'epic_notes'
  end

  it 'does not match invalid epic notes endpoint' do
    result = described_class.match(
      '/groups/my-group/-/and-subgroup/-/epics/1/notes'
    )

    expect(result).to be_blank
  end

  context 'k8s pod logs' do
    it 'matches with pod_name and container_name' do
      result = described_class.match(
        '/environments/7/pods/pod_name/containers/container_name/logs/k8s.json'
      )

      expect(result).to be_present
      expect(result.name).to eq 'k8s_pod_logs'
    end

    it 'matches with pod_name' do
      result = described_class.match(
        '/environments/7/pods/pod_name/containers/logs/k8s.json'
      )

      expect(result).to be_present
      expect(result.name).to eq 'k8s_pod_logs'
    end

    it 'matches without pod_name and container_name' do
      result = described_class.match(
        '/environments/7/pods/containers/logs/k8s.json'
      )

      expect(result).to be_present
      expect(result.name).to eq 'k8s_pod_logs'
    end

    it 'does not match non json format' do
      result = described_class.match(
        '/environments/7/logs'
      )

      expect(result).not_to be_present
    end
  end
end
