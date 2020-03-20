# frozen_string_literal: true

require 'fast_spec_helper'
require_relative '../../../support/helpers/expect_offense'
require_relative '../../../../rubocop/cop/performance/avoid_io_read'

describe RuboCop::Cop::Performance::AvoidIoRead do
  include CopHelper
  include ExpectOffense

  subject(:cop) { described_class.new }

  shared_examples_for(:class_read) do |klass, fn|
    context "via #{klass}.#{fn}" do
      context 'and no length is specified' do
        it 'flags it as an offense' do
          inspect_source "stack_template = #{klass}.#{fn}(file_path)"

          expect(cop.offenses).not_to be_empty
        end
      end

      context 'and a length in bytes is specified' do
        it 'passes' do
          inspect_source "contents = #{klass}.#{fn}(file_path, 256)"

          expect(cop.offenses).to be_empty
        end
      end

      context 'and the path is in Rails.root' do
        it 'passes' do
          inspect_source "contents = #{klass}.#{fn}(Rails.root.join('path', 'to', 'file'))"
          expect(cop.offenses).to be_empty

          inspect_source "contents = #{klass}.#{fn}(Rails.root.join(path).to_s)"
          expect(cop.offenses).to be_empty

          inspect_source "contents = #{klass}.#{fn}" + '("\#{Rails.root}/path")'
          expect(cop.offenses).to be_empty
        end
      end
    end
  end

  shared_examples_for(:instance_read) do |fn|
    context "via instance.#{fn}" do
      context 'and no length is specified' do
        it 'flags it as an offense' do
          inspect_source "contents = instance.#{fn}"

          expect(cop.offenses).not_to be_empty
        end
      end

      context 'and a length in bytes is specified' do
        it 'passes' do
          inspect_source "contents = instance.#{fn}(256)"

          expect(cop.offenses).to be_empty
        end
      end

      %w(Rails.cache stdout stderr).each do |instance|
        context "and it is called on #{instance}" do
          it 'passes' do
            inspect_source "contents = #{instance}.#{fn}"

            expect(cop.offenses).to be_empty
          end
        end
      end
    end
  end

  context 'when reading IO streams into memory in their entirey' do
    %w(read readlines).each do |fn|
      it_behaves_like(:instance_read, fn)

      %w(IO File).each do |klass|
        it_behaves_like(:class_read, klass, fn)
      end
    end
  end
end
