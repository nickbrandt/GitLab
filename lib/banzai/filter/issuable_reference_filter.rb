# frozen_string_literal: true

module Banzai
  module Filter
    class IssuableReferenceFilter < AbstractReferenceFilter
      include FindByParent

      def record_identifier(record)
        record.iid.to_i
      end

      def parent_from_ref(ref)
        parent_per_reference[ref || current_parent_path]
      end
    end
  end
end
