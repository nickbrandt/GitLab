# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Geo::Fdw::Ci::JobArtifact, :geo, type: :model do
  context 'relationships' do
    it { is_expected.to belong_to(:project).class_name('Geo::Fdw::Project').inverse_of(:job_artifacts) }
  end
end
