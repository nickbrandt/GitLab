# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishIncidentService do
  let_it_be(:user) { create(:user) }
  let_it_be(:project, refind: true) { create(:project) }
  let_it_be(:issue) { create(:issue, project: project) }
  let_it_be(:settings) { create(:status_page_setting, :enabled, project: project) }
  let(:user_can_publish) { true }

  let(:service) do
    described_class.new(user: user, project: project, issue_id: issue.id)
  end

  subject(:result) { service.execute }

  describe '#execute' do
    before do
      stub_licensed_features(status_page: true)

      allow(user).to receive(:can?).with(:publish_status_page, project)
        .and_return(user_can_publish)
    end

    context 'when publishing succeeds' do
      it 'returns uploads incidents details and list' do
        expect_to_upload_details(issue)
        expect_to_upload_list

        expect(result).to be_success
      end
    end

    context 'when uploading details fails' do
      it 'propagates the exception' do
        expect_to_upload_details(issue, status: 404)

        expect { result }.to raise_error(StatusPage::Storage::Error)
      end
    end

    context 'when uploading list fails' do
      it 'returns error and skip list upload' do
        expect_to_upload_details(issue)
        expect_to_upload_list(status: 404)

        expect { result }.to raise_error(StatusPage::Storage::Error)
      end
    end

    context 'with unrelated issue' do
      let(:issue) { create(:issue) }

      it 'returns error issue not found' do
        expect(result).to be_error
        expect(result.message).to eq('Issue not found')
      end
    end

    context 'when user cannot publish' do
      let(:user_can_publish) { false }

      it 'returns error missing publish permission' do
        expect(result).to be_error
        expect(result.message).to eq('No publish permission')
      end
    end
  end

  private

  def expect_to_upload_details(issue, **kwargs)
    stub_upload_request(StatusPage::Storage.details_path(issue.iid), **kwargs)
  end

  def expect_to_upload_list(**kwargs)
    stub_upload_request(StatusPage::Storage.list_path, **kwargs)
  end

  def stub_upload_request(path, status: 200)
    stub_request(:put, %r{amazonaws.com/#{path}}).to_return(status: status)
  end
end
