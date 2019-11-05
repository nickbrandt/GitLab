# frozen_string_literal: true

require 'spec_helper'

describe Gitlab::Pagination::Keyset::RequestContext do
  let(:request) { double('request', params: params) }
  let(:params) { { id_after: 5, per_page: 10 } }

  describe '#page' do
    subject { described_class.new(request).page }

    it 'extracts last_value information' do
      page = subject

      expect(page.last_value).to eq(params[:id_after])
    end

    it 'extracts per_page information' do
      page = subject

      expect(page.per_page).to eq(params[:per_page])
    end

    context 'with no id_after value present' do
      let(:params) { { id_after: 5, per_page: 10 } }

      it 'indicates this is the first page' do
        page = subject

        expect(page.first_page?).to be_truthy
      end
    end
  end

  describe '#apply_headers' do
    let(:paged_relation) { double('paged relation', next_page: next_page) }
    let(:request) { double('request', url: "http://#{Gitlab.config.gitlab.host}/api/v4/projects?foo=bar") }
    let(:params) { { foo: 'bar' } }
    let(:request_context) { double('request context', params: params, request: request) }
    let(:next_page) { double('next page', last_value: 42, empty?: false) }

    subject { described_class.new(request_context).apply_headers(paged_relation) }

    it 'sets Links header with a link to the first page' do
      orig_uri = URI.parse(request_context.request.url)

      expect(request_context).to receive(:header) do |name, header|
        expect(name).to eq('Links')

        first_link, _ = /<([^>]+)>; rel="first"/.match(header).captures

        URI.parse(first_link).tap do |uri|
          expect(uri.host).to eq(orig_uri.host)
          expect(uri.path).to eq(orig_uri.path)

          query = CGI.parse(uri.query)
          expect(query.except('id_after')).to eq(CGI.parse(orig_uri.query).except("id_after"))
          expect(query['id_after']).to be_empty
        end
      end

      subject
    end

    it 'sets Links header with a link to the next page' do
      orig_uri = URI.parse(request_context.request.url)

      expect(request_context).to receive(:header) do |name, header|
        expect(name).to eq('Links')

        first_link, _ = /<([^>]+)>; rel="next"/.match(header).captures

        URI.parse(first_link).tap do |uri|
          expect(uri.host).to eq(orig_uri.host)
          expect(uri.path).to eq(orig_uri.path)

          query = CGI.parse(uri.query)
          expect(query.except('id_after')).to eq(CGI.parse(orig_uri.query).except("id_after"))
          expect(query['id_after']).to eq(["42"])
        end
      end

      subject
    end
  end
end
