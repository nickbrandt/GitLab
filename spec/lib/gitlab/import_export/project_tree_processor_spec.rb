# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeProcessor do
  let(:tree) do
    {
      simple: 42,
      k1: { "v1": 1 },
      k2: ["v2"],
      array: [
        { k1: { "v1": 1 } },
        { k2: ["v2"] }
      ],
      nested: {
        k1: { "v1": 1 },
        k2: ["v2"],
        k3: ["don't touch"]
      }
    }
  end

  let(:processed_tree) { subject.process(tree) }

  it 'returns the processed tree' do
    expect(processed_tree).to be(tree)
  end

  it 'de-duplicates equal values' do
    expect(processed_tree[:k1]).to be(processed_tree[:array][0][:k1])
    expect(processed_tree[:k1]).to be(processed_tree[:nested][:k1])
    expect(processed_tree[:k2]).to be(processed_tree[:array][1][:k2])
    expect(processed_tree[:k2]).to be(processed_tree[:nested][:k2])
  end

  it 'keeps unique entries intact' do
    expect(processed_tree[:simple]).to eq(42)
    expect(processed_tree[:nested][:k3]).to eq(["don't touch"])
  end

  it 'maintains object equality' do
    expect { processed_tree }.not_to change { tree }
  end

  context 'obtaining a suitable processor' do
    context 'when the project file is above the size threshold' do
      it 'returns an optimizing processor' do
        stub_project_file_size(subject.class::LARGE_PROJECT_FILE_SIZE_BYTES)

        expect(subject.class.new_for_file('/path/to/project.json')).to(
          be_an_instance_of(Gitlab::ImportExport::ProjectTreeProcessor)
        )
      end
    end

    context 'when the file is below the size threshold' do
      it 'returns a no-op processor' do
        stub_project_file_size(subject.class::LARGE_PROJECT_FILE_SIZE_BYTES - 1)

        expect(subject.class.new_for_file('/path/to/project.json')).to(
          be_an_instance_of(Gitlab::ImportExport::IdentityProjectTreeProcessor)
        )
      end
    end

    def stub_project_file_size(size)
      allow(File).to receive(:size).and_return(size)
    end
  end
end
