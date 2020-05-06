# frozen_string_literal: true

require 'spec_helper'

describe StatusPage::PublishService do
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

    describe 'publish details' do
      context 'when upload succeeds' do
        it 'uploads incident details and list' do
          expect_to_upload_details(issue)
          expect_to_upload_list

          expect(result).to be_success
        end
      end

      context 'when upload fails' do
        it 'propagates the exception' do
          expect_to_upload_details(issue, status: 404)

          expect { result }.to raise_error(StatusPage::Storage::Error)
        end
      end
    end

    describe 'unpublish details' do
      let_it_be(:issue) { create(:issue, :confidential, project: project) }

      context 'when unpublish succeeds' do
        it 'unpublishes incident details and uploads incident list' do
          expect_to_unpublish(error?: false)
          expect_to_upload_list

          expect(result).to be_success
        end
      end

      context 'when unpublish service responses with error' do
        it 'returns the response' do
          response = expect_to_unpublish(error?: true)

          expect(result).to be(response)
        end
      end
    end

    describe 'publish list' do
      context 'when upload fails' do
        it 'returns error and skip list upload' do
          expect_to_upload_details(issue)
          expect_to_upload_list(status: 404)

          expect { result }.to raise_error(StatusPage::Storage::Error)
        end
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

  def expect_to_unpublish(**response_kwargs)
    service_response = double(**response_kwargs)
    expect_next_instance_of(StatusPage::UnpublishDetailsService) do |service|
      expect(service).to receive(:execute).and_return(service_response)
    end

    service_response
  end

  def expect_to_upload_details(issue, **kwargs)
    stub_aws_request(:put, StatusPage::Storage.details_path(issue.iid), **kwargs)
  end

  def expect_to_delete_details(issue, **kwargs)
    stub_aws_request(:delete, StatusPage::Storage.details_path(issue.iid), **kwargs)
  end

  def expect_to_upload_list(**kwargs)
    stub_aws_request(:put, StatusPage::Storage.list_path, **kwargs)
  end

  def stub_aws_request(method, path, status: 200)
    stub_request(method, %r{amazonaws.com/#{path}}).to_return(status: status)
  end
end
