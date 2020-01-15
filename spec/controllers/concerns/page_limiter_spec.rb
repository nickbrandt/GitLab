# frozen_string_literal: true

require 'spec_helper'

class PageLimiterSpecController < ApplicationController
  include PageLimiter

  limit_pages 2 do
    raise "block response"
  end

  def page_out_of_bounds
    raise "method response"
  end
end

describe PageLimiter do
  let(:controller_class) do
    PageLimiterSpecController
  end

  let(:instance) do
    controller_class.new
  end

  before do
    allow(instance).to receive(:params) do
      {
        controller: "explore/projects",
        action: "index"
      }
    end

    allow(instance).to receive(:request) do
      double(:request, user_agent: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)")
    end
  end

  describe ".max_page" do
    subject { controller_class.max_page }

    it { is_expected.to eq(2) }
  end

  describe ".page_limiter_block" do
    subject { controller_class.page_limiter_block }

    it "is an executable block" do
      expect { subject.call }.to raise_error("block response")
    end
  end

  describe ".set_max_page" do
    subject { controller_class.send(:set_max_page, page) }

    context "page is a number" do
      let(:page) { 2 }

      it { is_expected.to eq(page) }
    end

    context "page is a string" do
      let(:page) { "2" }

      it "raises an error" do
        expect { subject }.to raise_error(PageLimiter::PageLimitNotANumberError)
      end
    end

    context "page is nil" do
      let(:page) { nil }

      it "raises an error" do
        expect { subject }.to raise_error(PageLimiter::PageLimitNotANumberError)
      end
    end
  end

  describe "#page_out_of_bounds" do
    subject { instance.page_out_of_bounds }

    it "returns a bad_request header" do
      expect { subject }.to raise_error("method response")
    end
  end

  describe "#max_page_defined?" do
    using RSpec::Parameterized::TableSyntax
    subject { instance.send(:max_page_defined?) }

    where(:max_page, :result) do
      2     | true
      nil   | false
      0     | false
    end

    with_them do
      before do
        controller_class.instance_variable_set(:@max_page, max_page)
      end

      # Reset this afterwards to prevent polluting other specs
      after do
        controller_class.instance_variable_set(:@max_page, 2)
      end

      it { is_expected.to be(result) }
    end
  end

  describe "#check_page_number" do
    let(:max_page) { 2 }

    subject { instance.send(:check_page_number) { "test" } }

    before do
      allow(instance).to receive(:params) { { page: page.to_s } }
    end

    context "page is over the limit" do
      let(:page) { max_page + 1 }

      it "records the interception" do
        expect(instance).to receive(:record_interception)
        # Need this second expectation to cancel out the exception
        expect { subject }.to raise_error("block response")
      end

      context "block is given" do
        it "calls the block" do
          expect { subject }.to raise_error("block response")
        end
      end

      context "block is not given" do
        before do
          allow(controller_class).to receive(:page_limiter_block) { nil }
        end

        it "calls the #page_out_of_bounds method" do
          expect { subject }.to raise_error("method response")
        end
      end
    end

    context "page is not over the limit" do
      let(:page) { max_page }

      it "yields" do
        expect(subject).to eq("test")
      end
    end
  end

  describe "#default_page_out_of_bounds_response" do
    subject { instance.send(:default_page_out_of_bounds_response) }

    it "returns a bad_request header" do
      expect(instance).to receive(:head).with(:bad_request)

      subject
    end
  end

  describe "#record_interception" do
    subject { instance.send(:record_interception) }

    it "records a metric counter" do
      expect(Gitlab::Metrics).to receive(:counter).with(
        :gitlab_page_out_of_bounds,
        controller: "explore/projects",
        action: "index",
        agent: "Mozilla/5.0 (compatible; Googlebot/2.1; +http://www.google.com/bot.html)"
      )

      subject
    end
  end
end
