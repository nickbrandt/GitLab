# frozen_string_literal: true

# Generated HTML is transformed back to GFM by app/assets/javascripts/behaviors/markdown/nodes/reference.js
module Banzai
  module Filter
    # Base class for GitLab Flavored Markdown reference filters.
    #
    # References within <pre>, <code>, <a>, and <style> elements are ignored.
    #
    # Context options:
    #   :project (required) - Current project, ignored if reference is cross-project.
    #   :only_path          - Generate path-only links.
    class ReferenceFilter < HTML::Pipeline::Filter
      include RequestStoreReferenceCache
      include OutputSafety

      class << self
        attr_accessor :reference_type

        def call(doc, context = nil, result = nil)
          new(doc, context, result).call_and_update_nodes
        end
      end

      def initialize(doc, context = nil, result = nil)
        super

        if update_nodes_enabled?
          @changed_nodes = {}
          @nodes = self.result[:nodes]
        end
      end

      def call_and_update_nodes
        update_nodes_enabled? ? with_update_nodes { call } : call
      end

      # Returns a data attribute String to attach to a reference link
      #
      # attributes - Hash, where the key becomes the data attribute name and the
      #              value is the data attribute value
      #
      # Examples:
      #
      #   data_attribute(project: 1, issue: 2)
      #   # => "data-reference-type=\"SomeReferenceFilter\" data-project=\"1\" data-issue=\"2\""
      #
      #   data_attribute(project: 3, merge_request: 4)
      #   # => "data-reference-type=\"SomeReferenceFilter\" data-project=\"3\" data-merge-request=\"4\""
      #
      # Returns a String
      def data_attribute(attributes = {})
        attributes = attributes.reject { |_, v| v.nil? }

        attributes[:reference_type] ||= self.class.reference_type
        attributes[:container] ||= 'body'
        attributes[:placement] ||= 'top'
        attributes[:html] ||= 'true'
        attributes.delete(:original) if context[:no_original_data]
        attributes.map do |key, value|
          %Q(data-#{key.to_s.dasherize}="#{escape_once(value)}")
        end.join(' ')
      end

      def ignore_ancestor_query
        @ignore_ancestor_query ||= begin
          parents = %w(pre code a style)
          parents << 'blockquote' if context[:ignore_blockquotes]

          parents.map { |n| "ancestor::#{n}" }.join(' or ')
        end
      end

      def project
        context[:project]
      end

      def group
        context[:group]
      end

      def skip_project_check?
        context[:skip_project_check]
      end

      def reference_class(type, tooltip: true)
        gfm_klass = "gfm gfm-#{type}"

        return gfm_klass unless tooltip

        "#{gfm_klass} has-tooltip"
      end

      # Ensure that a :project key exists in context
      #
      # Note that while the key might exist, its value could be nil!
      def validate
        needs :project unless skip_project_check?
      end

      # Iterates over all <a> and text() nodes in a document.
      #
      # Nodes are skipped whenever their ancestor is one of the nodes returned
      # by `ignore_ancestor_query`. Link tags are not processed if they have a
      # "gfm" class or the "href" attribute is empty.
      def each_node
        return to_enum(__method__) unless block_given?

        doc.xpath(query).each do |node|
          yield node
        end
      end

      # Returns an Array containing all HTML nodes.
      def nodes
        @nodes ||= each_node.to_a
      end

      # Yields the link's URL and inner HTML whenever the node is a valid <a> tag.
      def yield_valid_link(node)
        link = CGI.unescape(node.attr('href').to_s)
        inner_html = node.inner_html

        return unless link.force_encoding('UTF-8').valid_encoding?

        yield link, inner_html
      end

      def replace_text_when_pattern_matches(node, index, pattern)
        return unless node.text =~ pattern

        content = node.to_html
        html = yield content

        replace_text_with_html(node, index, html) unless html == content
      end

      def replace_link_node_with_text(node, index)
        html = yield

        replace_text_with_html(node, index, html) unless html == node.text
      end

      def replace_link_node_with_href(node, index, link)
        html = yield

        replace_text_with_html(node, index, html) unless html == link
      end

      def text_node?(node)
        node.is_a?(Nokogiri::XML::Text)
      end

      def element_node?(node)
        node.is_a?(Nokogiri::XML::Element)
      end

      private

      def query
        @query ||= %Q{descendant-or-self::text()[not(#{ignore_ancestor_query})]
        | descendant-or-self::a[
          not(contains(concat(" ", @class, " "), " gfm ")) and not(@href = "")
        ]}
      end

      def replace_text_with_html(node, index, html)
        if update_nodes_enabled?
          replace_and_update_changed_nodes(node, index, html)
        else
          node.replace(html)
        end
      end

      def replace_and_update_changed_nodes(node, index, html)
        previous_node = node.previous
        next_node = node.next
        parent_node = node.parent
        # Unfortunately node.replace(html) returns re-parented nodes, not the actual replaced nodes in the doc
        # We need to find the actual nodes in the doc that were replaced
        node.replace(html)
        @changed_nodes[index] = []

        # We find first replaced node. If previous_node is nil, we take first parent child
        replaced_node = previous_node ? previous_node.next : parent_node&.children&.first

        # We iterate from first to last replaced node and store replaced nodes in @changed_nodes
        while replaced_node && replaced_node != next_node
          @changed_nodes[index] << replaced_node.xpath(query)
          replaced_node = replaced_node.next
        end

        @changed_nodes[index].flatten!
      end

      def only_path?
        context[:only_path]
      end

      def with_update_nodes
        @changed_nodes = {}
        yield.tap { update_nodes! }
      end

      # Once Filter completes replacing nodes, we update nodes with @changed_nodes
      def update_nodes!
        @changed_nodes.sort_by { |index, _changed_nodes| -index }.each do |index, changed_nodes|
          nodes[index, 1] = changed_nodes
        end
        result[:nodes] = nodes
      end

      def update_nodes_enabled?
        Feature.enabled?(:update_nodes_for_banzai_reference_filter, project)
      end
    end
  end
end
