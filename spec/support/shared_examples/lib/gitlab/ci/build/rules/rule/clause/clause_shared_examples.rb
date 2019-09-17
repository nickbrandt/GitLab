# frozen_string_literal: true

RSpec.shared_examples 'a glob matching rule' do
  using RSpec::Parameterized::TableSyntax

  where(:case_name, :globs, :files, :satisfied) do
    'exact top-level match'      | ['Dockerfile']               | { 'Dockerfile' => '', 'Gemfile' => '' }           | true
    'exact top-level no match'   | ['Dockerfile']               | { 'Gemfile' => '' }                               | false
    'pattern top-level match'    | ['Docker*']                  | { 'Dockerfile' => '', 'Gemfile' => '' }           | true
    'pattern top-level no match' | ['Docker*']                  | { 'Gemfile' => '' }                               | false
    'exact nested match'         | ['project/build.properties'] | { 'project/build.properties' => '' }              | true
    'exact nested no match'      | ['project/build.properties'] | { 'project/README.md' => '' }                     | false
    'pattern nested match'       | ['src/**/*.go']              | { 'src/gitlab.com/goproject/goproject.go' => '' } | true
    'pattern nested no match'    | ['src/**/*.go']              | { 'src/gitlab.com/goproject/README.md' => '' }    | false
    'leading slash no match'     | ['/*.go']                    | { 'main.go' => '' }                               | false
  end

  with_them do
    it 'checks if any files exist' do
      expect(subject.satisfied_by?(pipeline, nil)).to eq(satisfied)
    end
  end
end
