require 'spec_helper'

describe Gitlab::Geo::LfsTransfer do
  include ::EE::GeoHelpers

  set(:primary_node) { create(:geo_node, :primary) }
  set(:secondary_node) { create(:geo_node) }
  set(:lfs_object) { create(:lfs_object, :with_file, :correct_oid) }

  subject do
    described_class.new(lfs_object)
  end

  context '#download_from_primary' do
    before do
      stub_current_geo_node(secondary_node)
    end

    context 'when the destination filename is a directory' do
      it 'returns a failed result' do
        expect(lfs_object).to receive(:file).and_return(double(path: '/tmp'))

        result = subject.download_from_primary

        expect_result(result, success: false, bytes_downloaded: 0, primary_missing_file: false)
      end
    end

    context 'when the HTTP response is successful' do
      it 'returns a successful result' do
        content = lfs_object.file.read
        size = content.bytesize
        expect(FileUtils).to receive(:mv).with(anything, lfs_object.file.path).and_call_original
        response = double(:response, success?: true)
        expect(Gitlab::HTTP).to receive(:get).and_yield(content.to_s).and_return(response)

        result = subject.download_from_primary

        expect_result(result, success: true, bytes_downloaded: size, primary_missing_file: false)
        stat = File.stat(lfs_object.file.path)
        expect(stat.size).to eq(size)
        expect(stat.mode & 0777).to eq(0666 - File.umask)
        expect(File.binread(lfs_object.file.path)).to eq(content)
      end
    end

    context 'when the HTTP response is unsuccessful' do
      context 'when the HTTP response indicates a missing file on the primary' do
        it 'returns a failed result indicating primary_missing_file' do
          expect(FileUtils).not_to receive(:mv).with(anything, lfs_object.file.path).and_call_original
          response = double(:response, success?: false, code: 404, msg: "No such file")
          expect(File).to receive(:read).and_return("{\"geo_code\":\"#{Gitlab::Geo::FileUploader::FILE_NOT_FOUND_GEO_CODE}\"}")
          expect(Gitlab::HTTP).to receive(:get).and_return(response)

          result = subject.download_from_primary

          expect_result(result, success: false, bytes_downloaded: 0, primary_missing_file: true)
        end
      end

      context 'when the HTTP response does not indicate a missing file on the primary' do
        it 'returns a failed result' do
          expect(FileUtils).not_to receive(:mv).with(anything, lfs_object.file.path).and_call_original
          response = double(:response, success?: false, code: 404, msg: 'No such file')
          expect(Gitlab::HTTP).to receive(:get).and_return(response)

          result = subject.download_from_primary

          expect_result(result, success: false, bytes_downloaded: 0, primary_missing_file: false)
        end
      end
    end

    context 'when Tempfile fails' do
      it 'returns a failed result' do
        expect(Tempfile).to receive(:new).and_raise(Errno::ENAMETOOLONG)

        result = subject.download_from_primary

        expect(result.success).to eq(false)
        expect(result.bytes_downloaded).to eq(0)
      end
    end

    context "invalid path" do
      it 'logs an error if the destination directory could not be created' do
        expect(lfs_object).to receive(:file).and_return(double(path: '/foo/bar'))

        allow(FileUtils).to receive(:mkdir_p) { raise Errno::EEXIST }

        expect(subject).to receive(:log_error).with("unable to create directory /foo: File exists")
        result = subject.download_from_primary

        expect(result.success).to eq(false)
        expect(result.bytes_downloaded).to eq(0)
      end
    end

    context 'when the checksum of the downloaded file does not match' do
      it 'returns a failed result' do
        bad_content = 'corrupted!!!'
        response = double(:response, success?: true)
        expect(Gitlab::HTTP).to receive(:get).and_yield(bad_content).and_return(response)

        result = subject.download_from_primary

        expect_result(result, success: false, bytes_downloaded: bad_content.bytesize, primary_missing_file: false)
      end
    end
  end

  def expect_result(result, success:, bytes_downloaded:, primary_missing_file:)
    expect(result.success).to eq(success)
    expect(result.bytes_downloaded).to eq(bytes_downloaded)
    expect(result.primary_missing_file).to eq(primary_missing_file)

    # Sanity check to help ensure a valid test
    expect(success).not_to be_nil
    expect(primary_missing_file).not_to be_nil
  end
end
