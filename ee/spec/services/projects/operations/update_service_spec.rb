# frozen_string_literal: true

require 'spec_helper'

describe Projects::Operations::UpdateService do
  let_it_be(:user) { create(:user) }

  let(:project) { create(:project) }
  let(:result) { subject.execute }

  subject { described_class.new(project, user, params) }

  describe '#execute' do
    context 'tracing setting' do
      context 'with valid params' do
        let(:params) do
          {
            tracing_setting_attributes: {
              external_url: 'http://some-url.com'
            }
          }
        end

        context 'with an existing setting' do
          before do
            create(:project_tracing_setting, project: project)
          end

          shared_examples 'setting deletion' do
            let!(:original_params) { params.deep_dup }

            it 'deletes the setting' do
              expect(result[:status]).to eq(:success)
              expect(project.reload.tracing_setting).to be_nil
            end

            it 'does not modify original params' do
              subject.execute

              expect(params).to eq(original_params)
            end
          end

          it 'updates the setting' do
            expect(project.tracing_setting).not_to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.tracing_setting.external_url)
              .to eq('http://some-url.com')
          end

          context 'with missing external_url' do
            before do
              params[:tracing_setting_attributes].delete(:external_url)
            end

            it_behaves_like 'setting deletion'
          end

          context 'with empty external_url' do
            before do
              params[:tracing_setting_attributes][:external_url] = ''
            end

            it_behaves_like 'setting deletion'
          end

          context 'with blank external_url' do
            before do
              params[:tracing_setting_attributes][:external_url] = ' '
            end

            it_behaves_like 'setting deletion'
          end
        end

        context 'without an existing setting' do
          it 'creates a setting' do
            expect(project.tracing_setting).to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.tracing_setting.external_url)
              .to eq('http://some-url.com')
          end
        end
      end

      context 'with empty params' do
        let(:params) { {} }

        let!(:tracing_setting) do
          create(:project_tracing_setting, project: project)
        end

        it 'does nothing' do
          expect(result[:status]).to eq(:success)
          expect(project.reload.tracing_setting).to eq(tracing_setting)
        end
      end
    end

    context 'alerting setting' do
      before do
        stub_licensed_features(prometheus_alerts: true)
        project.add_maintainer(user)
      end

      shared_examples 'no operation' do
        it 'does nothing' do
          expect(result[:status]).to eq(:success)
          expect(project.reload.alerting_setting).to be_nil
        end
      end

      context 'with valid params' do
        let(:params) { { alerting_setting_attributes: alerting_params } }

        shared_examples 'setting creation' do
          it 'creates a setting' do
            expect(project.alerting_setting).to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.alerting_setting).not_to be_nil
          end
        end

        context 'when regenerate_token is not set' do
          let(:alerting_params) { { token: 'some token' } }

          context 'with an existing setting' do
            let!(:alerting_setting) do
              create(:project_alerting_setting, project: project)
            end

            it 'ignores provided token' do
              expect(result[:status]).to eq(:success)
              expect(project.reload.alerting_setting.token)
                .to eq(alerting_setting.token)
            end
          end

          context 'without an existing setting' do
            it_behaves_like 'setting creation'
          end
        end

        context 'when regenerate_token is set' do
          let(:alerting_params) { { regenerate_token: true } }

          context 'with an existing setting' do
            let(:token) { 'some token' }

            let!(:alerting_setting) do
              create(:project_alerting_setting, project: project, token: token)
            end

            it 'regenerates token' do
              expect(result[:status]).to eq(:success)
              expect(project.reload.alerting_setting.token).not_to eq(token)
            end
          end

          context 'without an existing setting' do
            it_behaves_like 'setting creation'

            context 'without license' do
              before do
                stub_licensed_features(prometheus_alerts: false)
              end

              it_behaves_like 'no operation'
            end

            context 'with insufficient permissions' do
              before do
                project.add_reporter(user)
              end

              it_behaves_like 'no operation'
            end
          end
        end
      end

      context 'with empty params' do
        let(:params) { {} }

        it_behaves_like 'no operation'
      end
    end

    context 'status page setting' do
      before do
        project.add_maintainer(user)
      end

      shared_examples 'no operation' do
        it 'does nothing' do
          expect(result[:status]).to eq(:success)
          expect(project.reload.status_page_setting).to be_nil
        end
      end

      context 'with valid params' do
        let(:params) do
          {
            status_page_setting_attributes: attributes_for(:status_page_setting, aws_s3_bucket_name: 'test')
          }
        end

        context 'with an existing setting' do
          before do
            create(:status_page_setting, project: project)
          end

          it 'updates the setting' do
            expect(project.status_page_setting).not_to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.status_page_setting.aws_s3_bucket_name)
              .to eq('test')
          end

          context 'with aws key and secret blank' do
            let(:params) do
              {
                status_page_setting_attributes: {
                  aws_access_key: '',
                  aws_secret_key: '',
                  aws_s3_bucket_name: '',
                  aws_region: ''
                }
              }
            end

            it 'destroys the status_page_setting entry in DB' do
              expect(result[:status]).to eq(:success)

              expect(project.reload.status_page_setting).to be_nil
            end
          end

          context 'with not all keys blank' do
            let(:params) do
              {
                status_page_setting_attributes: {
                  aws_s3_bucket_name: 'test',
                  aws_region: 'ap-southeast-2',
                  aws_access_key: '',
                  aws_secret_key: project.reload.status_page_setting.masked_aws_secret_key
                }
              }
            end

            it 'returns a validation error' do
              expect(result[:status]).to eq(:error)
            end
          end
        end

        context 'without an existing setting' do
          it 'creates a setting' do
            expect(project.status_page_setting).to be_nil

            expect(result[:status]).to eq(:success)
            expect(project.reload.status_page_setting.aws_s3_bucket_name)
              .to eq('test')
          end
        end
      end
    end
  end
end
