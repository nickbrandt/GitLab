# frozen_string_literal: true

require 'spec_helper'

describe Ci::DeployFrozenService do

  subject { described_class.new(build: build).execute }

  context 'when build is not an environment' do
    let(:build) { create :ci_build }

    it 'is not frozen' do
      expect(subject).to be_falsy
    end
  end

  context 'when build is an non-opted in enviroment' do
    let(:build) { create :ci_build, :deploy_to_production }

    it 'is not frozen' do
      expect(subject).to be_falsy
    end
  end

  context 'when eligible build is outside the freeze period' do
    let(:build) { create :ci_build, :deploy_to_production }

    it 'is not frozen' do
      expect(subject).to be_falsy
    end
  end

  context 'when eligible build is inside the freeze period' do
    let(:build) { create :ci_build, :deploy_to_production }

    it 'is not frozen' do
      expect(subject).to be_falsy
    end
  end

end