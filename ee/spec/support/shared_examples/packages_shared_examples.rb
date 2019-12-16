# frozen_string_literal: true

shared_examples 'returns packages' do |container_type, user_type|
  context "for #{user_type}" do
    before do
      send(container_type)&.send("add_#{user_type}", user) unless user_type == :no_type
    end

    it 'returns success response' do
      subject

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'returns a valid response schema' do
      subject

      expect(response).to match_response_schema('public_api/v4/packages/packages', dir: 'ee')
    end

    it 'returns two packages' do
      subject

      expect(json_response.length).to eq(2)
      expect(json_response.map { |package| package['id'] }).to contain_exactly(package1.id, package2.id)
    end
  end
end

shared_examples 'returns packages with subgroups' do |container_type, user_type|
  context "with subgroups for #{user_type}" do
    before do
      send(container_type)&.send("add_#{user_type}", user) unless user_type == :no_type
    end

    it 'returns success response' do
      subject

      expect(response).to have_gitlab_http_status(:success)
    end

    it 'returns a valid response schema' do
      subject

      expect(response).to match_response_schema('public_api/v4/packages/packages', dir: 'ee')
    end

    it 'returns three packages' do
      subject

      expect(json_response.length).to eq(3)
      expect(json_response.map { |package| package['id'] }).to contain_exactly(package1.id, package2.id, package3.id)
    end
  end
end

shared_examples 'rejects packages access' do |container_type, user_type, status|
  context "for #{user_type}" do
    before do
      send(container_type)&.send("add_#{user_type}", user) unless user_type == :no_type
    end

    it "returns #{status}" do
      subject

      expect(response).to have_gitlab_http_status(status)
    end
  end
end

shared_examples 'returns paginated packages' do
  let(:per_page) { 2 }

  context 'when viewing the first page' do
    let(:page) { 1 }

    it 'returns first 2 packages' do
      get api(url, user), params: { page: page, per_page: per_page }

      expect_paginated_array_response([package1.id, package2.id])
    end
  end

  context 'when viewing the second page' do
    let(:page) { 2 }

    it 'returns first 2 packages' do
      get api(url, user), params: { page: page, per_page: per_page }

      expect_paginated_array_response([package3.id, package4.id])
    end
  end
end
