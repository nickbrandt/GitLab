# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::ImportExport::ProjectTreeProcessor do
  let(:tree) do
    {
      simple: 42,
      duped_hash_with_id: { "id": 0, "v1": 1 },
      duped_hash_no_id: { "v1": 1 },
      duped_array: ["v2"],
      array: [
        { duped_hash_with_id: { "id": 0, "v1": 1 } },
        { duped_array: ["v2"] },
        { duped_hash_no_id: { "v1": 1 } }
      ],
      nested: {
        duped_hash_with_id: { "id": 0, "v1": 1 },
        duped_array: ["v2"],
        array: ["don't touch"]
      }
    }.with_indifferent_access
  end

  let(:processed_tree) { subject.process(tree) }

  it 'returns the processed tree' do
    expect(processed_tree).to be(tree)
  end

  it 'de-duplicates equal values' do
    expect(processed_tree[:duped_hash_with_id]).to be(processed_tree[:array][0][:duped_hash_with_id])
    expect(processed_tree[:duped_hash_with_id]).to be(processed_tree[:nested][:duped_hash_with_id])
    expect(processed_tree[:duped_array]).to be(processed_tree[:array][1][:duped_array])
    expect(processed_tree[:duped_array]).to be(processed_tree[:nested][:duped_array])
  end

  it 'does not de-duplicate hashes without IDs' do
    expect(processed_tree[:duped_hash_no_id]).to eq(processed_tree[:array][2][:duped_hash_no_id])
    expect(processed_tree[:duped_hash_no_id]).not_to be(processed_tree[:array][2][:duped_hash_no_id])
  end

  it 'keeps single entries intact' do
    expect(processed_tree[:simple]).to eq(42)
    expect(processed_tree[:nested][:array]).to eq(["don't touch"])
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
