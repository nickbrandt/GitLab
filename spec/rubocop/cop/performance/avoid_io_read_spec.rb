# frozen_string_literal: true

require 'fast_spec_helper'
# require 'rubocop'
require_relative '../../../support/helpers/expect_offense'
require_relative '../../../../rubocop/cop/performance/avoid_io_read'

describe RuboCop::Cop::Performance::AvoidIoRead do
  include CopHelper
  include ExpectOffense

  subject(:cop) { described_class.new }

  context 'when reading files into memory in their entirey' do
    %w(IO File).each do |klass|
      context "via #{klass}.read" do
        context 'and no length is specified' do
          it 'flags it as an offense' do
            inspect_source "stack_template = File.read(file_path)"

            expect(cop.offenses).not_to be_empty
          end
        end

        context 'and a length in bytes is specified' do
          it 'passes' do
            inspect_source "contents = #{klass}.read(file_path, 256)"

            expect(cop.offenses).to be_empty
          end
        end

        context 'and the path is in Rails.root' do
          it 'passes' do
            inspect_source "contents = #{klass}.read(Rails.root.join('path', 'to', 'file'))"
            expect(cop.offenses).to be_empty

            inspect_source "contents = #{klass}.read(Rails.root.join(path).to_s)"
            expect(cop.offenses).to be_empty

            inspect_source "contents = #{klass} " + '.read("\#{Rails.root}/path")'
            expect(cop.offenses).to be_empty
          end
        end
      end

      context "via #{klass}.readlines" do
        context 'and no length is specified' do
          it 'flags it as an offense' do
            inspect_source "contents = #{klass}.readlines(file_path)"

            expect(cop.offenses.size).to eq(1)
          end
        end

        context 'and a length in bytes is specified' do
          it 'passes' do
            inspect_source "contents = #{klass}.readlines(file_path, 256)"

            expect(cop.offenses).to be_empty
          end
        end
      end
    end

    context 'via file.read' do
      context 'and no length is specified' do
        it 'flags it as an offense' do
          inspect_source 'contents = file.read'

          expect(cop.offenses).not_to be_empty
        end
      end

      context 'and a length in bytes is specified' do
        it 'passes' do
          inspect_source 'contents = file.read(256)'

          expect(cop.offenses).to be_empty
        end
      end

      %w(Rails.cache stdout stderr).each do |target|
        context "and it is called on #{target}" do
          it 'passes' do
            inspect_source "contents = #{target}.read"

            expect(cop.offenses).to be_empty
          end
        end
      end
    end

    context 'via file.readlines' do
      context 'and no length is specified' do
        it 'flags it as an offense' do
          inspect_source 'contents = file.readlines'

          expect(cop.offenses).not_to be_empty
        end
      end

      context 'and a length in bytes is specified' do
        it 'passes' do
          inspect_source 'contents = file.readlines(256)'

          expect(cop.offenses).to be_empty
        end
      end
    end
  end
end
