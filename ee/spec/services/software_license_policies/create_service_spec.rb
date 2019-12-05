# frozen_string_literal: true

require 'spec_helper'

describe SoftwareLicensePolicies::CreateService do
  let(:project) { create(:project) }
  let(:params) { { name: 'ExamplePL/2.1', approval_status: 'blacklisted' } }

  let(:user) do
    create(:user).tap do |u|
      project.add_maintainer(u)
    end
  end

  before do
    stub_licensed_features(license_management: true)
  end

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'with license management unavailable' do
      before do
        stub_licensed_features(license_management: false)
      end

      it 'does not creates a software license policy' do
        expect { subject.execute }.to change { project.software_license_policies.count }.by(0)
      end
    end

    context 'with a user who is allowed to admin' do
      it 'creates one software license policy correctly' do
        expect { subject.execute }.to change { project.software_license_policies.count }.from(0).to(1)

        software_license_policy = project.software_license_policies.last
        expect(software_license_policy).to be_persisted
        expect(software_license_policy.name).to eq(params[:name])
        expect(software_license_policy.classification).to eq('denied')
      end

      context 'when valid parameters are specified' do
        where(:approval_status, :expected_classification) do
          [
            %w[approved approved],
            %w[denied denied],
            %w[blacklisted denied]
          ]
        end

        with_them do
          let(:params) { { name: 'MIT', approval_status: approval_status } }
          let(:result) { subject.execute }

          before do
            allow(RefreshLicenseComplianceChecksWorker).to receive(:perform_async)
            result
          end

          specify { expect(result[:status]).to be(:success) }
          specify { expect(result[:software_license_policy]).to be_present }
          specify { expect(result[:software_license_policy]).to be_persisted }
          specify { expect(result[:software_license_policy].name).to eql(params[:name]) }
          specify { expect(result[:software_license_policy].classification).to eql(expected_classification) }
          specify { expect(RefreshLicenseComplianceChecksWorker).to have_received(:perform_async).with(project.id) }
        end
      end

      context "when an argument error is raised" do
        before do
          allow_any_instance_of(Project).to receive(:software_license_policies).and_raise(ArgumentError)
        end

        specify { expect(subject.execute[:status]).to be(:error) }
        specify { expect(subject.execute[:message]).to be_present }
        specify { expect(subject.execute[:http_status]).to be(400) }
      end

      context "when invalid input is provided" do
        before do
          params[:approval_status] = nil
        end

        specify { expect(subject.execute[:status]).to be(:error) }
        specify { expect(subject.execute[:message]).to be_present }
        specify { expect(subject.execute[:http_status]).to be(400) }
      end
    end

    context 'with a user not allowed to admin' do
      let(:user) { create(:user) }

      it 'does not create a software license policy' do
        expect { subject.execute }.to change { project.software_license_policies.count }.by(0)
      end
    end
  end
end
