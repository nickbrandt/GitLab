# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Filter::DesignReferenceFilter do
  include FilterSpecHelper
  include DesignManagementTestHelpers

  # Persistent stuff we only want to create once
  let_it_be(:issue)    { create(:issue) }
  let_it_be(:issue_b)  { create(:issue, project: issue.project) }
  let_it_be(:design_a) { create(:design, :with_versions, issue: issue) }
  let_it_be(:design_b) { create(:design, :with_versions, issue: issue_b) }
  let_it_be(:developer) { create(:user).tap { |u| issue.project.add_developer(u) } }

  let_it_be(:project2)         { create(:project).tap { |p| p.add_developer(developer) } }
  let_it_be(:issue2)           { create(:issue, project: project2) }
  let_it_be(:x_project_design) { create(:design, :with_versions, issue: issue2) }

  # Transitory stuff we can compute cheaply from other things
  let(:design) { design_a }
  let(:project) { issue.project }
  let(:reference) { design.to_reference }
  let(:input_text) { "Added #{reference}" }
  let(:doc) { process_doc(input_text) }
  let(:current_user) { developer }

  def process_doc(text)
    reference_filter(text, project: project, current_user: current_user)
  end

  def process(text)
    process_doc(text).to_html
  end

  before do
    enable_design_management
  end

  shared_examples 'a no-op filter' do
    it 'does nothing' do
      expect(process(input_text)).to eq(input_text)
    end
  end

  shared_examples 'a good link reference' do
    let(:link) { doc.css('a').first }
    let(:href) { path_for_design(design) }
    let(:title) { design.filename }

    it 'produces a good link', :aggregate_failures do
      expect(link.attr('href')).to eq(href)
      expect(link.attr('title')).to eq(title)
      expect(link.attr('class')).to eq('gfm gfm-design has-tooltip')
      expect(link.attr('data-project')).to eq(project.id.to_s)
      expect(link.attr('data-issue')).to eq(issue.id.to_s)
      expect(link.attr('data-original')).to eq(reference)
      expect(link.attr('data-reference-type')).to eq('design')
      expect(link.text).to eq(design.to_reference)
    end
  end

  describe '.call' do
    it 'requires project context' do
      expect { described_class.call('') }.to raise_error(ArgumentError, /:project/)
    end
  end

  describe 'support for redaction' do
    before do
      enable_design_management
    end

    it 'supports the reference redactor' do
      res = reference_pipeline(redact: true).to_document(input_text)

      expect(res.css('a').first).to be_present
    end
  end

  describe '#call' do
    describe 'feature flags' do
      context 'design management is not enabled' do
        before do
          enable_design_management(false, true)
        end

        it_behaves_like 'a no-op filter'
      end

      context 'design reference filter is not enabled' do
        before do
          enable_design_management(true, false)
        end

        it_behaves_like 'a no-op filter'
      end
    end
  end

  %w(pre code a style).each do |elem|
    context "wrapped in a <#{elem}/>" do
      let(:input_text) { "<#{elem}>Design #{design.to_reference}</#{elem}>" }

      it_behaves_like 'a no-op filter'
    end
  end

  describe '.parse_symbol' do
    where(:filename) do
      [
        ['simple.png'],
        ['SIMPLE.PNG'],
        ['has spaces.png'],
        ['has-hyphen.jpg'],
        ['snake_case.svg'],
        ['has ] right bracket.gif'],
        [%q{has slashes \o/.png}],
        [%q{has "quote" 'marks'.gif}],
        [%q{<a href="has">html elements</a>.gif}]
      ]
    end

    with_them do
      where(:fullness) do
        [
          [true],
          [false]
        ]
      end

      with_them do
        let(:design) { build(:design, issue: issue, filename: filename) }
        let(:reference) { design.to_reference(full: fullness) }
        let(:parsed) do
          m = parse(reference)
          described_class.parse_symbol(m[described_class.object_sym], m) if m
        end

        def parse(ref)
          described_class.object_class.reference_pattern.match(ref)
        end

        it 'can parse the reference' do
          expect(parsed).to have_attributes(
            filename: filename,
            issue_iid: issue.iid
          )
        end
      end
    end
  end

  describe '.object_sym' do
    let(:subject) { described_class.object_sym }

    it { is_expected.to eq(:design) }
  end

  describe '.object_class' do
    let(:subject) { described_class.object_class }

    it { is_expected.to eq(::DesignManagement::Design) }
  end

  describe '#data_attributes_for' do
    let(:subject) { filter_instance.data_attributes_for(input_text, project, design) }

    it do
      is_expected.to include(issue: design.issue_id,
                             original: input_text,
                             project: project.id,
                             design: design.id)
    end
  end

  context 'a design with a quoted filename' do
    let(:filename) { %q{A "very" good file.png} }
    let(:design) { create(:design, :with_versions, issue: issue, filename: filename) }

    it 'links to the design' do
      expect(doc.css('a').first.attr('href'))
        .to eq path_for_design(design)
    end
  end

  context 'internal reference' do
    it_behaves_like 'a reference containing an element node'

    context "the reference is valid" do
      context 'the user does not have permission to read this project' do
        let(:current_user) { build_stubbed(:user) }

        it_behaves_like 'a no-op filter'
      end

      context 'the user has permission' do
        it_behaves_like 'a good link reference'
      end

      context 'the filename needs to be escaped' do
        let(:xss) do
          <<~END
            <script type="application/javascript">
              alert('xss')
            </script>
          END
        end

        let(:filename) { %Q{#{xss}.png} }
        let(:design) { create(:design, :with_versions, filename: filename, issue: issue) }

        it 'leaves the text as is, but escapes the title', :aggregate_failures do
          expect(doc.text).to eq(input_text)
          expect(doc.css('a').first.attr('title')).to eq(design.filename)
        end
      end
    end

    context "the reference is to a non-existant design" do
      let(:reference) { build(:design).to_reference }

      it 'ignores it' do
        expect(process(reference)).to eq(reference)
      end
    end
  end

  context 'URL reference' do
    let(:reference) { url_for_design(design) }

    it 'matches the link_reference_pattern' do
      expect(reference).to match(DesignManagement::Design.link_reference_pattern)
    end

    it 'constructs the appropriate references_per_parent structure' do
      filter = filter_instance

      filter.call

      expect(filter.references_per_parent).to eq({
        project.full_path => [filter.record_identifier(design)].to_set
      })
    end

    it_behaves_like 'a good link reference' do
      let(:href) { reference }
    end
  end

  context 'cross-project / cross-namespace complete reference' do
    let(:reference) { x_project_design.to_reference(project) }

    it_behaves_like 'a reference containing an element node'

    it 'links to a valid reference' do
      expect(doc.css('a').first.attr('href'))
        .to eq path_for_design(x_project_design)
    end

    context 'the current user does not have access to that project' do
      let(:current_user) { build_stubbed(:user) }

      it_behaves_like 'a no-op filter'
    end

    it 'link has valid text' do
      expect(doc.css('a').first.text).to eql("#{project2.full_path}##{issue.iid}[#{x_project_design.filename}]")
    end

    it 'includes default classes' do
      expect(doc.css('a').first.attr('class')).to eq 'gfm gfm-design has-tooltip'
    end

    context 'the reference is invalid' do
      let(:reference) { x_project_design.to_reference(project).gsub(/jpg/, 'gif') }

      it_behaves_like 'a no-op filter'
    end
  end

  describe 'performance' do
    let!(:design_c) { create(:design, :with_versions, issue: issue) }
    let!(:design_d) { create(:design, :with_versions, issue: issue_b) }
    let!(:design_e) { create(:design, :with_versions, issue: create(:issue, project: x_project_design.project)) }

    it 'is linear in the number of projects each design refers to' do
      one_ref_per_project = <<~MD
      Design #{design_a.to_reference}, #{x_project_design.to_reference(project)}
      MD

      multiple_references = <<~MD
      Designs:
       * #{design_a.to_reference}
       * #{design_b.to_reference}
       * #{design_c.to_reference}
       * #{design_d.to_reference}
       * #{x_project_design.to_reference(project)}
       * #{design_e.to_reference(project)}
       * #1[not a valid reference.gif]
      MD

      baseline = ActiveRecord::QueryRecorder.new { process(one_ref_per_project) }

      # each project where the current_user has :read_design permission requires 5 queries:
      #  * SELECT  "project_features".* FROM "project_features"
      #     :in `feature_available?'*/
      #  * SELECT MAX("project_authorizations"."access_level") ...
      #     :in `block in max_member_access_for_user_ids'
      #  * SELECT "issues".* FROM "issues" WHERE "issues"."project_id" = 1 AND ...
      #      :in `parent_records'*/
      #  * SELECT "_designs".* FROM "_designs"
      #      WHERE "issue_id" IN (..) AND "filename" IN ('homescreen-1.jpg', ...)
      #      :in `parent_records'*/
      #  * SELECT  "routes".* FROM "routes" WHERE "routes"."source_id" = 1 AND "routes"."source_type" = 'Namespace' LIMIT 1
      #      :in `full_path'*/
      #  nb: routes is a polymorphic association, and cannot be optimised by the
      #  use of `Project.includes(:route)
      # and 3 if not:
      #  * SELECT  "project_features".* FROM "project_features"
      #     :in `feature_available?'*/
      #  * SELECT MAX("project_authorizations"."access_level") ...
      #     :in `block in max_member_access_for_user_ids'
      #  * SELECT  "users".* FROM "users" WHERE "users"."id" = 5 LIMIT 1 :in `owner'*/
      #  At this point we know that the current_user is not authorised.
      #
      # In addition there is a 1 query overhead for all the projects at the
      # start. Currently, the baseline for 2 projects is `2 * 5 + 1 = 11` queries
      #
      expect { process(multiple_references) }.not_to exceed_query_limit(baseline.count)
    end
  end
end
