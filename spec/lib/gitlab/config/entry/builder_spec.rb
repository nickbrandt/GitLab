# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Config::Entry::Builder, :aggregate_failures do
  let(:parent_node) { parent_klass.new(config) }
  let(:config) do
    {
      hello: :world,
      database_password: :passw0rd
    }
  end

  subject(:builder) { described_class.new }

  describe '#push_entries_config!' do
    before do
      builder.push_entries_config!(Class, { foo: :bar })
    end

    it 'assigns classes to entries_klasses' do
      expect(builder.instance_variable_get(:@entries_klasses)).to eq(Class)
    end

    it 'assigns attributes to entries_attributes' do
      expect(builder.instance_variable_get(:@entries_attributes)).to eq({ foo: :bar })
    end
  end

  describe '#build_factory!' do
    let(:entry_klass) { Gitlab::Config::Entry::Node }

    before do
      builder.build_factory!('hello', entry_klass, reserved: true)
    end

    it 'assigns nodes' do
      nodes = builder.instance_variable_get(:@nodes)
      node = nodes['hello']
      node_attributes = node.instance_variable_get(:@attributes)

      expect(node.class).to eq(Gitlab::Config::Entry::Factory)
      expect(node_attributes).to eq(default: nil, key: "hello", reserved: true)
      expect(node.reserved?).to eq(true)
      expect(node.entry_class).to eq(entry_klass)
    end
  end

  describe '#create_entries' do
    shared_examples 'builds entries' do
      it 'defines hello' do
        expect(entries[:hello].class).to eq(Gitlab::Config::Entry::Node)
        expect(entries[:hello].value).to eq(:world)
        expect(entries[:hello].description).to eq('test object hello')
        expect(entries[:hello].metadata).to eq(name: :hello)
        expect(entries[:hello].default).to eq('antarctica')
      end

      it 'defines second key' do
        expect(entries[:database_password].value).to eq(:passw0rd)
      end
    end

    let(:entries) { parent_node.class.send('builder').create_entries(config, parent_node) }

    context 'when entries_klasses is a class' do
      let(:parent_klass) { define_parent_klass(entries_klass: Gitlab::Config::Entry::Node) }

      it_behaves_like 'builds entries'
    end

    context 'when entries_klasses is an array containing a single item' do
      let(:parent_klass) { define_parent_klass(entries_klass: [Gitlab::Config::Entry::Node]) }

      it_behaves_like 'builds entries'
    end

    context 'when entries_klasses is an array containing multiple items' do
      let(:parent_klass) { define_parent_klass(entries_klass: [Class, Gitlab::Config::Entry::Node]) }

      before do
        allow(parent_klass).to receive(:find_type).and_return(Gitlab::Config::Entry::Node)
      end

      it_behaves_like 'builds entries'
    end

    context 'when entries_klasses is nil' do
      let(:parent_klass) { define_parent_klass(entries_klass: nil) }

      it 'returns self with no entries' do
        expect(entries).to eq({})
      end
    end

    context 'when entries_klasses is not supported' do
      let(:parent_klass) { define_parent_klass(entries_klass: 'Class') }

      it 'raises an error' do
        expect { entries }.to raise_error(NoMethodError)
      end
    end

    def define_parent_klass(entries_klass:)
      Class.new(Gitlab::Config::Entry::Node) do
        include Gitlab::Config::Entry::Configurable

        entries entries_klass,
          description: 'test object %s',
          inherit: true,
          reserved: true,
          default: 'antarctica'
      end
    end
  end
end
