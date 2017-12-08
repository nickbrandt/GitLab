<<<<<<< HEAD
module Banzai
  module ReferenceParser
    # The actual parser is implemented in the EE mixin
    class EpicParser < IssuableParser
      prepend EE::Banzai::ReferenceParser::EpicParser

      self.reference_type = :epic

      def records_for_nodes(_nodes)
        {}
      end
    end
  end
end
||||||| merged common ancestors
=======
module Banzai
  module ReferenceParser
    # The actual parser is implemented in the EE mixin
    class EpicParser < IssuableParser
      self.reference_type = :epic

      def records_for_nodes(_nodes)
        {}
      end
    end
  end
end
>>>>>>> ce/10-3-stable
