# frozen_string_literal: true

require 'gitlab-dangerfiles'
require 'gitlab/dangerfiles/spec_helper'

require_relative '../../../tooling/danger/product_intelligence'
require_relative '../../../tooling/danger/project_helper'

RSpec.describe Tooling::Danger::ProductIntelligence do
  include_context "with dangerfile"

  let(:fake_danger) { DangerSpecHelper.fake_danger.include(described_class) }
  let(:fake_project_helper) { double('fake-project-helper', helper: fake_helper).tap { |h| h.class.include(Tooling::Danger::ProjectHelper) } }

  subject(:product_intelligence) { fake_danger.new(helper: fake_helper) }

  before do
    allow(product_intelligence).to receive(:project_helper).and_return(fake_project_helper)
  end

  describe '#matching_files?' do
    subject { product_intelligence.matching_files?(file, extension, pattern) }

    context 'when in CI context' do
      shared_examples 'changelog optional text' do |key|
        specify do
          expect(subject).to include('CHANGELOG missing')
          expect(subject).to include('bin/changelog -m 1234 "Fake Title"')
          expect(subject).to include('bin/changelog --ee -m 1234 "Fake Title"')
        end
      end

      before do
        allow(fake_helper).to receive(:ci?).and_return(true)
      end

      context "when title is not changed from sanitization", :aggregate_failures do
        let(:mr_title) { 'Fake Title' }

        it_behaves_like 'changelog optional text'
      end

      context "when title needs sanitization", :aggregate_failures do
        let(:mr_title) { 'DRAFT: Fake Title' }

        it_behaves_like 'changelog optional text'
      end
    end

    context 'when in local context' do
      let(:mr_title) { 'Fake Title' }

      before do
        allow(fake_helper).to receive(:ci?).and_return(false)
      end

      specify do
        expect(subject).to include('CHANGELOG missing')
        expect(subject).not_to include('bin/changelog')
      end
    end
  end
end
