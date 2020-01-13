# frozen_string_literal: true

require 'spec_helper'

describe Banzai::Pipeline::GfmPipeline do
  include FilterSpecHelper
  include DesignManagementTestHelpers

  let_it_be(:project) { create(:project, :repository) }
  let_it_be(:current_user) { create(:user).tap { |u| project.add_developer(u) } }

  def process_doc(text)
    described_class.call(text, project: project, current_user: current_user)
  end

  class References
    def initialize(current_project)
      @current_project = current_project
      @references = []
    end

    def append(factory, *traits, **attrs)
      thing = FactoryBot.create(factory, *traits, **attrs)
      @references << thing
      thing
    end

    def to_md
      @references.map { |r| "* #{r.to_reference(@current_project)}" }.join("\n")
    end
  end

  describe 'DesignReferenceFilter' do
    let_it_be(:markdown) do
      refs = References.new(project)
      i = refs.append(:issue, project: project)
      refs.append(:design, :with_versions, issue: i, project: project)
      refs.to_md
    end

    context 'is enabled' do
      before do
        enable_design_management(true, true)
      end

      it 'finds and processes the design references' do
        output = process_doc(markdown)[:output]

        expect(output.css('a.gfm-design')).to be_present
        expect(output.css('a.gfm-issue')).to be_present
      end
    end

    context 'is not enabled' do
      before do
        enable_design_management(true, false)
      end

      it 'finds and processes the design references' do
        output = process_doc(markdown)[:output]

        expect(output.css('a.gfm-design')).to be_empty
        expect(output.css('a.gfm-issue')).to be_present
      end
    end
  end

  describe 'performance impact of design reference filter' do
    describe 'processing 1000 references' do
      let_it_be(:markdown) do
        refs = References.new(project)
        projects = [project] + Array.new(9).map { create(:project, :repository) }
        projects.each do |p|
          p.add_developer(current_user)
          5.times do
            i = refs.append(:issue, project: p)
            19.times do
              refs.append(:design, issue: i, project: p)
            end
          end
        end
        refs.to_md
      end

      let_it_be(:markdown_no_designs) do
        refs = References.new(project)
        projects = [project] + Array.new(9).map { create(:project, :repository) }
        projects.each do |p|
          p.add_developer(current_user)
          100.times { refs.append(:issue, project: p) }
        end
        refs.to_md
      end

      shared_examples_for 'acceptable performance' do
        it 'has at least 1000 lines to process' do
          expect(input_text.split(/\n/).count).to be >= 1000
        end

        it 'does not issue an insane number of queries' do
          expect { process_doc(input_text) }.not_to exceed_query_limit(75)
        end
      end

      shared_examples_for 'acceptable pipeline performance' do
        context 'when there are many designs and many issues referenced' do
          let(:input_text) { markdown }

          it_behaves_like 'acceptable performance'
        end

        context 'when there are no designs referenced' do
          let(:input_text) { markdown_no_designs }

          it_behaves_like 'acceptable performance'
        end
      end

      context 'design reference filters are enabled' do
        before do
          enable_design_management(true, true)
        end

        it_behaves_like 'acceptable pipeline performance'
      end

      context 'design reference filters are disabled' do
        before do
          enable_design_management(true, false)
        end

        it_behaves_like 'acceptable pipeline performance'
      end
    end
  end
end
