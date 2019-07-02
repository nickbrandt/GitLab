# frozen_string_literal: true

require 'spec_helper'

describe Elastic::MultiVersionClassProxy do
  subject { described_class.new(ProjectSnippet) }

  describe '#version' do
    it 'returns class proxy in specified version' do
      result = subject.version('V12p1')

      expect(result).to be_a(Elastic::V12p1::SnippetClassProxy)
      expect(result.target).to eq(ProjectSnippet)
    end
  end

  describe 'method forwarding' do
    let(:old_target) { double(:old_target) }
    let(:new_target) { double(:new_target) }
    let(:response) do
      { "_index" => "gitlab-test", "_type" => "doc", "_id" => "snippet_1", "_version" => 3, "result" => "updated", "_shards" => { "total" => 2, "successful" => 1, "failed" => 0 }, "created" => false }
    end

    before do
      allow(subject).to receive(:elastic_reading_target).and_return(old_target)
      allow(subject).to receive(:elastic_writing_targets).and_return([old_target, new_target])
    end

    it 'forwards write methods to all targets' do
      Elastic::V12p1::SnippetClassProxy.write_methods.each do |method|
        expect(new_target).to receive(method).and_return(response)
        expect(old_target).to receive(method).and_return(response)

        subject.public_send(method)
      end
    end

    it 'forwards read methods to only reading target' do
      expect(old_target).to receive(:search)
      expect(new_target).not_to receive(:search)

      subject.search

      expect(subject).not_to respond_to(:method_missing)
    end
  end
end
