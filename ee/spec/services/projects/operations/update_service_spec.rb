# frozen_string_literal: true

require 'spec_helper'

describe Projects::Operations::UpdateService do
  subject { described_class.new(project, user, params) }

  let(:result) { subject.execute }

  set(:user) { create(:user) }
  set(:project) { create(:project) }

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
  end
end
