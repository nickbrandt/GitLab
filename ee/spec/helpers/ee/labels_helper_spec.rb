# frozen_string_literal: true

require 'spec_helper'

describe LabelsHelper do
  set(:project) { create(:project) }
  set(:label) { create(:label, project: project) }
  set(:scoped_label) { create(:label, name: 'key::value', project: project) }

  describe '#render_label' do
    context 'with scoped labels enabled' do
      before do
        stub_licensed_features(scoped_labels: true)
      end

      it 'includes link to scoped labels documentation' do
        expect(render_label(scoped_label)).to match(%r(<span.+>#{scoped_label.name}</span><a.+>.*question-circle.*</a>))
      end

      it 'does not include link to scoped label documentation for common labels' do
        expect(render_label(label)).to match(%r(<span.+>#{label.name}</span>$))
      end
    end

    context 'with scoped labels disabled' do
      before do
        stub_licensed_features(scoped_labels: false)
      end

      it 'does not include link to scoped documentation' do
        expect(render_label(scoped_label)).to match(%r(<span.+>#{scoped_label.name}</span>$))
      end
    end
  end
end
