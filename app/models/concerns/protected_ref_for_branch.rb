# frozen_string_literal: true

module ProtectedRefForBranch
  include ProtectedRef
end

ProtectedRefForBranch::ClassMethods.prepend('EE::ProtectedRef')
