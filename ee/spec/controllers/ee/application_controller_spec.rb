# frozen_string_literal: true
require 'spec_helper'

RSpec.describe ApplicationController do
  describe '#current_plan' do
    controller(described_class) do
      def index
        Labkit::Context.with_context do |context|
          render json: context.to_h
        end
      end
    end

    let_it_be(:user) { create(:user) }
    let_it_be(:namespace) { create :namespace }
    let_it_be(:project) { create :project, namespace: namespace }

    before do
      sign_in(user)
    end

    context 'when should_check_namespace_plan is true' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(true)
      end

      subject { controller.send(:current_plan) }

      context 'when only namespace is set' do
        it 'has the namespace plan' do
          controller.instance_variable_set(:@namespace, namespace)

          get :index, format: :json

          expect(subject).to be_a(String)
          expect(subject).to eq(namespace.actual_plan_name)
        end
      end

      context 'when project and namespace are set' do
        it 'has the namespace plan' do
          controller.instance_variable_set(:@namespace, namespace)
          controller.instance_variable_set(:@project, project)

          get :index, format: :json

          expect(subject).to be_a(String)
          expect(subject).to eq(namespace.actual_plan_name)
        end
      end

      context 'when only project is set' do
        it 'has project namespace plan' do
          controller.instance_variable_set(:@project, project)

          get :index, format: :json

          expect(subject).to be_a(String)
          expect(subject).to eq(project.namespace.actual_plan_name)
        end
      end

      context 'when no project or namespace are set' do
        it 'has current plan nil' do
          controller.instance_variable_set(:@namespace, nil)
          controller.instance_variable_set(:@project, nil)
          get :index, format: :json

          expect(subject).to eq(nil)
        end
      end
    end

    context 'when should_check_namespace_plan is false' do
      before do
        allow(::Gitlab::CurrentSettings).to receive(:should_check_namespace_plan?).and_return(false)
      end

      subject { controller.send(:current_plan) }

      context 'when only namespace is set' do
        it 'has the curent license plan' do
          controller.instance_variable_set(:@namespace, namespace)

          get :index, format: :json

          expect(subject).to be_a(String)
          expect(subject).to eq(License.current.plan)
        end
      end

      context 'when project and namespace are set' do
        it 'has the curent license plan' do
          controller.instance_variable_set(:@namespace, namespace)
          controller.instance_variable_set(:@project, project)

          get :index, format: :json

          expect(subject).to be_a(String)
          expect(subject).to eq(License.current.plan)
        end
      end

      context 'when only project is set' do
        it 'has the curent license plan' do
          controller.instance_variable_set(:@project, project)

          get :index, format: :json

          expect(subject).to be_a(String)
          expect(subject).to eq(License.current.plan)
        end
      end

      context 'when no project or namespace are set' do
        it 'has current plan nil' do
          controller.instance_variable_set(:@namespace, nil)
          controller.instance_variable_set(:@project, nil)
          get :index, format: :json

          expect(subject).to eq(nil)
        end
      end
    end
  end
end
