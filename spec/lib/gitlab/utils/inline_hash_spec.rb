# frozen_string_literal: true

require 'fast_spec_helper'

describe Gitlab::Utils::InlineHash do
  describe '.merge_keys' do
    subject { described_class.merge_keys(source) }

    context 'with string keys' do
      let(:source) do
        {
          nested_param: {
            key: 'Value'
          },
          'root_param' => 'Root',
          'very' => {
            'deep' => {
              'nested' => {
                'param' => 'Deep nested value'
              }
            }
          }
        }
      end

      it 'transforms a nested hash into a one-level hash' do
        is_expected.to eq(
          'nested_param.key' => 'Value',
          'root_param' => 'Root',
          'very.deep.nested.param' => 'Deep nested value'
        )
      end

      it 'retains key insertion order' do
        expect(subject.keys)
          .to eq(%w(nested_param.key root_param very.deep.nested.param))
      end

      context 'with a custom connector' do
        subject { described_class.merge_keys(source, connector: '::') }

        it 'uses the connector to merge keys' do
          is_expected.to eq(
            'nested_param::key' => 'Value',
            'root_param' => 'Root',
            'very::deep::nested::param' => 'Deep nested value'
          )
        end
      end

      context 'with a starter prefix' do
        subject { described_class.merge_keys(source, prefix: 'options') }

        it 'prefixes all the keys' do
          is_expected.to eq(
            'options.nested_param.key' => 'Value',
            'options.root_param' => 'Root',
            'options.very.deep.nested.param' => 'Deep nested value'
          )
        end
      end
    end

    context 'with un-nested symbol or numeric keys' do
      let(:unested_symbol_key_source) do
        {
          unnested_symbol_key: :unnested_symbol_value,
          12 => 22,
          nested_symbol_key: {
            nested_symbol_key_2: :nested_symbol_value
          }
        }
      end

      context 'without prefix' do
        subject { described_class.merge_keys(unested_symbol_key_source) }

        it 'converts only nested keys to inline strings' do
          is_expected.to eq(
            :unnested_symbol_key => :unnested_symbol_value,
            12 => 22,
            'nested_symbol_key.nested_symbol_key_2' => :nested_symbol_value
          )
        end
      end

      context 'with prefix' do
        subject { described_class.merge_keys(unested_symbol_key_source, prefix: 'options') }
        it 'converts prefixed keys to inline strings' do
          is_expected.to eq(
            'options.unnested_symbol_key' => :unnested_symbol_value,
            'options.12' => 22,
            'options.nested_symbol_key.nested_symbol_key_2' => :nested_symbol_value
          )
        end
      end
    end
  end
end
