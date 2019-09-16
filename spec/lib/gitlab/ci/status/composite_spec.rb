require 'spec_helper'

describe Gitlab::Ci::Status::Composite do
  set(:pipeline) { create(:ci_pipeline) }

  let(:composite_status) do
    described_class.new(
      all_statuses.pluck(:status, :allow_failure),
      status_key: 0,
      allow_failure_key: 0
    )
  end

  before(:all) do
    @statuses = HasStatus::STATUSES_ENUM.map do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, importing: true)]
    end.to_h

    @statuses_with_allow_failure = HasStatus::STATUSES_ENUM.map do |status, idx|
      [status, create(:ci_build, pipeline: pipeline, status: status, allow_failure: true, importing: true)]
    end.to_h
  end

  describe '#status' do
    subject { composite_status.status }

    shared_examples 'compares composite with SQL status' do
      it 'returns exactly the same result' do
        is_expected.to eq(Ci::Build.where(id: all_statuses).legacy_status)
      end
    end

    shared_examples 'validate all combinations' do |perms|
      HasStatus::STATUSES_ENUM.keys.combination(perms).each do |statuses|
        context "with #{statuses.join(",")}" do
          it_behaves_like 'compares composite with SQL status' do
            let(:all_statuses) do
              statuses.map { |status| @statuses[status] }
            end
          end

          HasStatus::STATUSES_ENUM.each do |allow_failure_status, _|
            context "and allow_failure #{allow_failure_status}" do
              it_behaves_like 'compares composite with SQL status' do
                let(:all_statuses) do
                  statuses.map { |status| @statuses[status] } +
                    [@statuses_with_allow_failure[allow_failure_status]]
                end
              end
            end
          end
        end
      end
    end

    it_behaves_like 'validate all combinations', 0
    it_behaves_like 'validate all combinations', 1
    it_behaves_like 'validate all combinations', 2
  end
end
