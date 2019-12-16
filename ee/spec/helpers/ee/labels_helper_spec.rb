# frozen_string_literal: true

require 'spec_helper'

describe LabelsHelper do
  let(:project) { create(:project) }
  let(:label) { build_stubbed(:label, project: project).present(issuable_subject: nil) }
  let(:scoped_label) { build_stubbed(:label, name: 'key::value', project: project).present(issuable_subject: nil) }

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

  describe '#label_dropdown_data' do
    subject { label_dropdown_data(edit_context, opts) }

    let(:opts) { { default_label: "Labels" } }
    let(:data) do
      {
        toggle: "dropdown",
        field_name: opts[:field_name] || "label_name[]",
        show_no: "true",
        show_any: "true",
        default_label: "Labels",
        scoped_labels: "false",
        scoped_labels_documentation_link: "/help/user/project/labels.md#scoped-labels"
      }
    end

    context 'when edit_context is a project' do
      let(:edit_context) { create(:project) }
      let(:label) { create(:label, project: edit_context, title: 'bug') }

      before do
        data.merge!({
          project_id: edit_context.id,
          namespace_path: edit_context.namespace.full_path,
          project_path: edit_context.path
        })
      end

      it { is_expected.to eq(data) }
    end

    context 'when edit_context is a group' do
      let(:edit_context) { create(:group) }
      let(:label) { create(:group_label, group: edit_context, title: 'bug') }

      before do
        data.merge!(group_id: edit_context.id)
      end

      it { is_expected.to eq(data) }
    end
  end
end
