# frozen_string_literal: true

require 'spec_helper'

describe CiMinutesUsageMailer do
  include EmailSpec::Matchers

  let(:namespace_name) { 'GROUP_NAME' }
  let(:recipients) { %w(bob@example.com john@example.com) }

  shared_examples 'mail format' do
    it { is_expected.to have_subject subject_text }
    it { is_expected.to bcc_to recipients }
    it { is_expected.to have_body_text body_text }
  end

  describe '#notify' do
    it_behaves_like 'mail format' do
      let(:subject_text) do
        "Action required: There are no remaining Pipeline minutes for #{namespace_name}"
      end

      let(:body_text) { "#{namespace_name} has run out of Shared Runner Pipeline minutes" }

      subject { described_class.notify(namespace_name, recipients) }
    end
  end

  describe '#notify_limit' do
    it_behaves_like 'mail format' do
      let(:percent) { 30 }
      let(:subject_text) do
        "Action required: Less than #{percent}% of Pipeline minutes remain for #{namespace_name}"
      end

      let(:body_text) { "#{namespace_name} has #{percent}% or less Shared Runner Pipeline minutes" }

      subject { described_class.notify_limit(namespace_name, recipients, percent) }
    end
  end
end
