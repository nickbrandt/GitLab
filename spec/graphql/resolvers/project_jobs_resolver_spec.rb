# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Resolvers::ProjectJobsResolver do
  include GraphqlHelpers

  let_it_be(:project) { create(:project, :repository, :public) }
  let_it_be(:irrelevant_project) { create(:project, :repository, :public) }
  let_it_be(:pipeline) { create(:ci_pipeline, project: project) }
  let_it_be(:irrelevant_pipeline) { create(:ci_pipeline, project: irrelevant_project) }

  let(:current_user) { create(:user) }
  let(:build_one) { create(:ci_build, :success, name: 'Build One', pipeline: pipeline) }
  let(:build_two) { create(:ci_build, :success, name: 'Build Two', pipeline: pipeline) }
  let(:build_three) { create(:ci_build, :failed, name: 'Build Three', pipeline: pipeline) }
  let(:irrelevant_build) { create(:ci_build, name: 'Irrelevant Build', pipeline: irrelevant_pipeline)}
  let(:args) { {} }

  subject { resolve_jobs(args) }

  describe '#resolve' do
    context 'with statuses argument' do
      let(:args) { { statuses: [Types::Ci::JobStatusEnum.values['SUCCESS'].value] } }

      it { is_expected.to contain_exactly(build_one, build_two) }
    end

    context 'without statuses argument' do
      it { is_expected.to contain_exactly(build_one, build_two, build_three) }
    end
  end

  private

  def resolve_jobs(args = {}, context = { current_user: current_user })
    resolve(described_class, obj: project, args: args, ctx: context)
  end
end
