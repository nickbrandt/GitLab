<<<<<<< HEAD
module Banzai
  module Filter
    # The actual filter is implemented in the EE mixin
    class EpicReferenceFilter < IssuableReferenceFilter
      prepend EE::Banzai::Filter::EpicReferenceFilter

      self.reference_type = :epic

      def self.object_class
        Epic
      end
    end
  end
end
||||||| merged common ancestors
=======
module Banzai
  module Filter
    # The actual filter is implemented in the EE mixin
    class EpicReferenceFilter < IssuableReferenceFilter
      self.reference_type = :epic

      def self.object_class
        Epic
      end
    end
  end
end
>>>>>>> ce/10-3-stable
