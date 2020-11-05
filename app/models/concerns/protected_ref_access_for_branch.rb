# frozen_string_literal: true

module ProtectedRefAccessForBranch
  include ProtectedRefAccess
end

ProtectedRefAccessForBranch.include('EE::ProtectedRefAccess::Scopes')
ProtectedRefAccessForBranch.prepend('EE::ProtectedRefAccess')
ProtectedRefAccessForBranch::ClassMethods.prepend('EE::ProtectedRefAccess::ClassMethods')
