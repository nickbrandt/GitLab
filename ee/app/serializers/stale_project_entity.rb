# frozen_string_literal: true

class StaleProjectEntity < ProjectEntity
  expose :unconfigured_scans
  expose :out_of_date_scans
end
