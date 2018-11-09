# frozen_string_literal: true

class MergeRequestPolicy < IssuablePolicy
end

MergeRequestPolicy.prepend(EE::MergeRequestPolicy)
