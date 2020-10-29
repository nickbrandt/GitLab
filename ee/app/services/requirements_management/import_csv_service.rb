# frozen_string_literal: true

module RequirementsManagement
  class ImportCsvService < ::Issuable::ImportCsv::BaseService
    def email_results_to_user
      Notify.import_requirements_csv_email(@user.id, @project.id, @results).deliver_later
    end

    private

    def create_issuable_class
      RequirementsManagement::CreateRequirementService
    end
  end
end
