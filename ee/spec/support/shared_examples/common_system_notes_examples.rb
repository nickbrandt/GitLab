# frozen_string_literal: true

shared_examples_for 'a project system note' do
  it 'has the project attribute set' do
    expect(subject.project).to eq project
  end

  it_behaves_like 'a system note', exclude_project: true
end
