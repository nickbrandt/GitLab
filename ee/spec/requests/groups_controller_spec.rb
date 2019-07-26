# frozen_string_literal: true

require 'spec_helper'

describe GroupsController, type: :request do
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
      let(:params) { { group: { ip_restriction_attributes: { range: range } } } }
      let(:range) { '192.168.0.0/24' }

      before do
        stub_licensed_features(group_ip_restriction: true)
        allow_any_instance_of(Gitlab::IpRestriction::Enforcer).to(
          receive(:allows_current_ip?).and_return(true))
      end

      context 'top-level group' do
        context 'when ip_restriction does not exist' do
          context 'valid param' do
            it 'creates ip restriction' do
              expect { subject }
                .to(change { group.reload.ip_restriction&.range }
                  .from(nil).to('192.168.0.0/24'))
              expect(response).to have_gitlab_http_status(302)
            end
          end

          context 'invalid param' do
            let(:range) { 'boom!' }

            it 'adds error message' do
              expect { subject }
                .not_to(change { group.reload.ip_restriction }.from(nil))
              expect(response).to have_gitlab_http_status(200)
              expect(response.body).to include('Ip restriction range is an invalid IP address range')
            end
          end
        end

        context 'when ip_restriction already exists' do
          let!(:ip_restriction) { IpRestriction.create!(group: group, range: '10.0.0.0/8') }
          let(:params) { { group: { ip_restriction_attributes: { id: ip_restriction.id, range: range } } } }

          context 'ip restriction param set' do
            context 'valid param' do
              it 'updates ip restriction' do
                expect { subject }
                  .to(change { group.reload.ip_restriction.range }
                    .from('10.0.0.0/8').to('192.168.0.0/24'))
                expect(response).to have_gitlab_http_status(302)
              end
            end

            context 'invalid param' do
              let(:range) { 'boom!' }

              it 'adds error message' do
                expect { subject }
                  .not_to(change { group.reload.ip_restriction.range }
                    .from('10.0.0.0/8'))
                expect(response).to have_gitlab_http_status(200)
                expect(response.body).to include('Ip restriction range is an invalid IP address range')
              end
            end
          end

          context 'empty ip restriction param' do
            let(:range) { '' }

            it 'deletes ip restriction' do
              expect { subject }
                .to(change { group.reload.ip_restriction }.to(nil))
              expect(response).to have_gitlab_http_status(302)
            end
          end
        end
      end

      context 'subgroup' do
        let(:group) { create(:group, :nested) }

        it 'does not create ip restriction' do
          expect { subject }
            .not_to change { group.reload.ip_restriction }.from(nil)
          expect(response).to have_gitlab_http_status(200)
          expect(response.body).to include('Ip restriction base IP subnet restriction only allowed for top-level groups')
        end
      end

      context 'with empty ip restriction param' do
        let(:params) do
          { group: { two_factor_grace_period: 42,
                     ip_restriction_attributes: { range: "" } } }
        end

        it 'updates group setting' do
          expect { subject }
            .to change { group.reload.two_factor_grace_period }.from(48).to(42)
          expect(response).to have_gitlab_http_status(302)
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
            .not_to change { group.reload.ip_restriction }.from(nil)
          expect(response).to have_gitlab_http_status(302)
        end
      end
    end
  end
end
