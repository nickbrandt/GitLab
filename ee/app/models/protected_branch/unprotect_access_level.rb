# frozen_string_literal: true

class ProtectedBranch::UnprotectAccessLevel < ActiveRecord::Base
  include ProtectedBranchAccess
end
