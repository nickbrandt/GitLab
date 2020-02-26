# frozen_string_literal: true

module StatusPage
  class IncidentSerializer < BaseSerializer
    entity IncidentEntity

    def represent_list(resource)
      represent(resource, except: [:comments])
    end

    def represent_details(resource, user_notes)
      represent(resource, user_notes: user_notes)
    end

    private :represent
  end
end
