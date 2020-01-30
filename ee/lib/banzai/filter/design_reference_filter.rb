# frozen_string_literal: true

module Banzai
  module Filter
    class DesignReferenceFilter < AbstractReferenceFilter
      include Gitlab::Allowable

      Identifier = Struct.new(:issue_iid, :filename, keyword_init: true)

      self.reference_type = :design

      # This filter must be enabled by setting the following flags:
      #  - design_management
      #  - design_management_reference_filter_gfm_pipeline
      def call
        return doc unless enabled?

        super
      end

      def find_object(project, identifier)
        records_per_parent[project][identifier]
      end

      def parent_records(project, identifiers)
        return [] unless can_read_designs?(project)

        iids      = identifiers.map(&:issue_iid).to_set
        filenames = identifiers.map(&:filename).to_set
        issues    = project.issues.where(iid: iids)
        issue_map = issues.index_by(&:id)

        designs(issues.to_a, filenames).select do |d|
          issue = issue_map[d.issue_id]
          # assign values we have already fetched
          d.project = project
          d.issue = issue
          identifiers.include?(Identifier.new(filename: d.filename, issue_iid: issue.iid))
        end
      end

      def relation_for_paths(paths)
        super.includes(:route, :namespace, :group)
      end

      def parent_type
        :project
      end

      # optimisation to reuse the parent_per_reference query information
      def parent_from_ref(ref)
        parent_per_reference[ref || current_parent_path]
      end

      def url_for_object(design, project)
        path_options = { vueroute: design.filename }
        Gitlab::Routing.url_helpers.designs_project_issue_path(project, design.issue, path_options)
      end

      def data_attributes_for(_text, _project, design, **_kwargs)
        super.merge(issue: design.issue_id)
      end

      def self.object_class
        ::DesignManagement::Design
      end

      def self.object_sym
        :design
      end

      def self.parse_symbol(raw, match_data)
        filename = parse_filename(raw, match_data)
        iid = match_data[:issue].to_i
        Identifier.new(filename: filename, issue_iid: iid)
      end

      def self.parse_filename(raw, match_data)
        if name = match_data[:simple_file_name]
          name
        elsif efn = match_data[:escaped_filename]
          efn.gsub(/(\\ \\ | \\ ")/x) { |x| x[1] }
        elsif b64_name = match_data[:base_64_encoded_name]
          Base64.decode64(b64_name)
        else
          raise "Unexpected name format: #{raw}"
        end
      end

      def record_identifier(design)
        Identifier.new(filename: design.filename, issue_iid: design.issue.iid)
      end

      private

      def can_read_designs?(project)
        DeclarativePolicy.user_scope { can?(current_user, :read_design, project) }
      end

      def designs(issues, filenames)
        DesignManagement::Design.on_issue(issues).with_filename(filenames)
      end

      def enabled?
        Feature.enabled?(:design_management_reference_filter_gfm_pipeline)
      end
    end
  end
end
