# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Aws::LaunchTypeHelper do
  let_it_be(:project) { create(:project) }
  let_it_be(:aws_launch_type_key) { described_class::AWS_LAUNCH_TYPE_KEY }

  subject { described_class.new(project) }

  describe '#aws_launch_type' do
    context 'when there is no ci variables attached to a project' do
      it 'is nil' do
        expect(subject.aws_launch_type).to be_nil
      end
    end

    context 'when there are ci variables attached to a project' do
      let!(:ci_variable) do
        create(:ci_variable, key: key, value: 'value', project: project, environment_scope: '*')
      end

      context 'and the correct AWS launch type variable has not been set' do
        let(:key) { 'AWS_OTHER_VARIABLE' }

        it 'is nil' do
          expect(subject.aws_launch_type).to be_nil
        end
      end

      context 'and the correct AWS launch type variable has been set' do
        let(:key) { aws_launch_type_key }

        it 'returns the right value' do
          expect(subject.aws_launch_type).to eq('value')
        end
      end
    end
  end

  describe '#launch_type_valid' do
    let!(:ci_variable) do
      create(:ci_variable, key: aws_launch_type_key, value: value, project: project, environment_scope: '*')
    end

    context 'when the launch type exists' do
      let(:value) { 'ECS' }

      it 'is valid' do
        expect(subject.launch_type_valid?).to be_truthy
      end
    end

    context 'when the launch type does not exist' do
      let(:value) { 'ABC' }

      it 'is not valid' do
        expect(subject.launch_type_valid?).to be_falsey
      end
    end
  end
end
