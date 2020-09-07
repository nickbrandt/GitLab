# frozen_string_literal: true

class ServiceList
  def initialize(batch, service_hash)
    @batch = batch
    @service_hash = service_hash
  end

  def to_array
    [Service, columns, values]
  end

  private

  attr_reader :batch, :service_hash

  def columns
    (service_hash.keys << 'project_id')
  end

  def values
    batch.map do |project_id|
      (service_hash.values << project_id)
    end
  end
end
