# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::LabelReferenceFilter do
  include FilterSpecHelper

  let(:project)      { create(:project, :public, name: 'sample-project') }
  let(:label)        { create(:label, name: 'label', project: project) }
  let(:scoped_label) { create(:label, name: 'key::value', project: project) }

  context 'with scoped labels enabled' do
    before do
      stub_licensed_features(scoped_labels: true)
    end

    it 'includes link to scoped documentation' do
      doc = reference_filter("See #{scoped_label.to_reference}")
      scope, name = scoped_label.name.split(Label::SCOPED_LABEL_SEPARATOR)

      expect(doc.to_html).to match(%r(<span.+><a.+><span.+>#{scope}</span><span.+>#{name}</span></a><a.+>.*question-circle.*</a></span>))
    end

    it 'does not include link to scoped documentation for common labels' do
      doc = reference_filter("See #{label.to_reference}")

      expect(doc.to_html).to match(%r(<span.+><a.+><span.+>#{label.name}</span></a></span>$))
    end
  end

  context 'with scoped labels disabled' do
    before do
      stub_licensed_features(scoped_labels: false)
    end

    it 'renders label as a common label' do
      doc = reference_filter("See #{scoped_label.to_reference}")

      expect(doc.to_html).to match(%r(<span.+><a.+><span.+>#{scoped_label.name}</span></a></span>$))
    end
  end
end
