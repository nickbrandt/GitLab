# frozen_string_literal: true

require 'spec_helper'

describe API::GroupPackages do
  let(:group) { create(:group, :public) }
  let(:project) { create(:project, :public, namespace: group) }
  let!(:package1) { create(:npm_package, project: project, version: '3.1.0', name: "@#{project.root_namespace.path}/foo1") }
  let!(:package2) { create(:nuget_package, project: project, version: '2.0.4') }
  let(:user) { create(:user) }

  subject { get api(url) }

  describe 'GET /groups/:id/packages' do
    let(:url) { "/groups/#{group.id}/packages" }
    let(:package_schema) { 'public_api/v4/packages/group_packages' }

    context 'with packages feature enabled' do
      before do
        stub_licensed_features(packages: true)
      end

      context 'with sorting' do
        let(:package3) { create(:maven_package, project: project, version: '1.1.1', name: 'zzz') }

        before do
          travel_to(1.day.ago) do
            package3
          end
        end

        context 'without sorting params' do
          let(:packages) { [package3, package1, package2] }

          it 'sorts by created_at asc' do
            subject

            expect(json_response.map { |package| package['id'] }).to eq(packages.map(&:id))
          end
        end

        it_behaves_like 'package sorting', 'name' do
          let(:packages) { [package1, package2, package3] }
        end

        it_behaves_like 'package sorting', 'created_at' do
          let(:packages) { [package3, package1, package2] }
        end

        it_behaves_like 'package sorting', 'version' do
          let(:packages) { [package3, package2, package1] }
        end

        it_behaves_like 'package sorting', 'type' do
          let(:packages) { [package3, package1, package2] }
        end
      end

      context 'with private group' do
        let(:group) { create(:group, :private) }
        let(:subgroup) { create(:group, :private, parent: group) }
        let(:project) { create(:project, :private, namespace: group) }
        let(:subproject) { create(:project, :private, namespace: subgroup) }

        context 'with unauthenticated user' do
          it_behaves_like 'rejects packages access', :group, :no_type, :not_found
        end

        context 'with authenticated user' do
          subject { get api(url, user) }

          it_behaves_like 'returns packages', :group, :owner
          it_behaves_like 'returns packages', :group, :maintainer
          it_behaves_like 'returns packages', :group, :developer
          it_behaves_like 'rejects packages access', :group, :reporter, :forbidden
          it_behaves_like 'rejects packages access', :group, :guest, :forbidden

          context 'with subgroup' do
            let(:subgroup) { create(:group, :private, parent: group) }
            let(:subproject) { create(:project, :private, namespace: subgroup) }
            let!(:package3) { create(:npm_package, project: subproject) }

            it_behaves_like 'returns packages with subgroups', :group, :owner
            it_behaves_like 'returns packages with subgroups', :group, :maintainer
            it_behaves_like 'returns packages with subgroups', :group, :developer
            it_behaves_like 'rejects packages access', :group, :reporter, :forbidden
            it_behaves_like 'rejects packages access', :group, :guest, :forbidden

            context 'excluding subgroup' do
              let(:url) { "/groups/#{group.id}/packages?exclude_subgroups=true" }

              it_behaves_like 'returns packages', :group, :owner
              it_behaves_like 'returns packages', :group, :maintainer
              it_behaves_like 'returns packages', :group, :developer
              it_behaves_like 'rejects packages access', :group, :reporter, :forbidden
              it_behaves_like 'rejects packages access', :group, :guest, :forbidden
            end
          end
        end
      end

      context 'with public group' do
        context 'with unauthenticated user' do
          it_behaves_like 'returns packages', :group, :no_type
        end

        context 'with authenticated user' do
          subject { get api(url, user) }

          it_behaves_like 'returns packages', :group, :owner
          it_behaves_like 'returns packages', :group, :maintainer
          it_behaves_like 'returns packages', :group, :developer
          it_behaves_like 'returns packages', :group, :reporter
          it_behaves_like 'returns packages', :group, :guest
        end
      end

      context 'with pagination params' do
        let!(:package3) { create(:npm_package, project: project) }
        let!(:package4) { create(:npm_package, project: project) }

        it_behaves_like 'returns paginated packages'
      end
    end

    context 'with packages feature disabled' do
      before do
        stub_licensed_features(packages: false)
      end

      it_behaves_like 'rejects packages access', :group, :no_type, :forbidden
    end
  end
end
