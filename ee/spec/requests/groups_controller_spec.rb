# frozen_string_literal: true

require 'spec_helper'

RSpec.describe GroupsController, type: :request do
  let(:user) { create(:user) }
  let(:group) { create(:group) }

  describe 'PUT update' do
    before do
      group.add_owner(user)
      login_as(user)

      stub_licensed_features(group_ip_restriction: true)
    end

    subject do
      put(group_path(group), params: params)
    end

    context 'setting ip_restriction' do
      let(:group) { create(:group) }
      let(:params) { { group: { ip_restriction_ranges: range } } }
      let(:range) { '192.168.0.0/24' }

      before do
        stub_licensed_features(group_ip_restriction: true)
        allow_any_instance_of(Gitlab::IpRestriction::Enforcer).to(
          receive(:allows_current_ip?).and_return(true))
      end

      context 'top-level group' do
        context 'when ip_restriction does not exist' do
          context 'valid param' do
            shared_examples 'creates ip restrictions' do
              it 'creates ip restrictions' do
                expect { subject }
                  .to(change { group.reload.ip_restrictions.map(&:range) }
                    .from([]).to(range.split(',')))
                expect(response).to have_gitlab_http_status(:found)
              end
            end

            context 'single IP subnet' do
              let(:range) { '192.168.0.0/24' }

              it_behaves_like 'creates ip restrictions'
            end

            context 'multiple IP subnets' do
              let(:range) { '192.168.0.0/24,192.168.0.1/8' }

              it_behaves_like 'creates ip restrictions'
            end
          end

          context 'invalid param' do
            let(:range) { 'boom!' }

            it 'adds error message' do
              expect { subject }
                .not_to(change { group.reload.ip_restrictions.count }.from(0))
              expect(response).to have_gitlab_http_status(:ok)
              expect(response.body).to include('Ip restrictions range is an invalid IP address range')
            end
          end
        end

        context 'when ip_restriction already exists' do
          let!(:ip_restriction) { IpRestriction.create!(group: group, range: '10.0.0.0/8') }
          let(:params) { { group: { ip_restriction_ranges: range } } }

          context 'ip restriction param set' do
            context 'valid param' do
              shared_examples 'updates ip restrictions' do
                it 'updates ip restrictions' do
                  expect { subject }
                    .to(change { group.reload.ip_restrictions.map(&:range) }
                      .from(['10.0.0.0/8']).to(range.split(',')))
                  expect(response).to have_gitlab_http_status(:found)
                end
              end

              context 'single subnet' do
                let(:range) { '192.168.0.0/24' }

                it_behaves_like 'updates ip restrictions'
              end

              context 'multiple subnets' do
                context 'a new subnet along with the existing one' do
                  let(:range) { '10.0.0.0/8,192.168.1.0/8' }

                  it_behaves_like 'updates ip restrictions'
                end

                context 'completely new range of subnets' do
                  let(:range) { '192.168.0.0/24,192.168.1.0/8' }

                  it_behaves_like 'updates ip restrictions'
                end
              end
            end

            context 'invalid param' do
              shared_examples 'does not update existing ip restrictions' do
                it 'does not change ip restriction records' do
                  expect { subject }
                    .not_to(change { group.reload.ip_restrictions.map(&:range) }
                      .from(['10.0.0.0/8']))
                end

                it 'adds error message' do
                  subject

                  expect(response).to have_gitlab_http_status(:ok)
                  expect(response.body).to include('Ip restrictions range is an invalid IP address range')
                end
              end

              context 'not a valid subnet' do
                let(:range) { 'boom!' }

                it_behaves_like 'does not update existing ip restrictions'
              end

              context 'multiple IP subnets' do
                context 'any one of them being not a valid' do
                  let(:range) { '192.168.0.0/24,boom!' }

                  it_behaves_like 'does not update existing ip restrictions'
                end
              end
            end
          end

          context 'empty ip restriction param' do
            let(:range) { '' }

            it 'deletes ip restriction' do
              expect { subject }
                .to(change { group.reload.ip_restrictions.count }.to(0))
              expect(response).to have_gitlab_http_status(:found)
            end
          end
        end
      end

      context 'subgroup' do
        let(:group) { create(:group, :nested) }

        it 'does not create ip restriction' do
          expect { subject }
            .not_to change { group.reload.ip_restrictions.count }.from(0)
          expect(response).to have_gitlab_http_status(:ok)
          expect(response.body).to include('Ip restrictions base IP subnet restriction only allowed for top-level groups')
        end
      end

      context 'with empty ip restriction param' do
        let(:params) do
          { group: { two_factor_grace_period: 42,
                     ip_restriction_ranges: "" } }
        end

        it 'updates group setting' do
          expect { subject }
            .to change { group.reload.two_factor_grace_period }.from(48).to(42)
          expect(response).to have_gitlab_http_status(:found)
        end

        it 'does not create ip restriction' do
          expect { subject }.not_to change { IpRestriction.count }
        end
      end

      context 'feature is disabled' do
        before do
          stub_licensed_features(group_ip_restriction: false)
        end

        it 'does not create ip restriction' do
          expect { subject }
            .not_to change { group.reload.ip_restrictions.count }.from(0)
          expect(response).to have_gitlab_http_status(:found)
        end
      end
    end
  end
end
