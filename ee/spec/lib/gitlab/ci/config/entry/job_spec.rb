# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Ci::Config::Entry::Job do
  let(:entry) { described_class.new(config, name: :rspec) }

  describe 'validations' do
    before do
      entry.compose!
    end

    context 'when entry value is not correct' do
      context 'when has needs' do
        context 'when needs is bridge type' do
          let(:config) do
            {
              script: 'echo',
              stage: 'test',
              needs: { pipeline: 'some/project' }
            }
          end

          it 'returns error about invalid needs type' do
            expect(entry).not_to be_valid
            expect(entry.errors).to contain_exactly('needs config uses invalid types: bridge')
          end
        end
      end
    end
  end
end
