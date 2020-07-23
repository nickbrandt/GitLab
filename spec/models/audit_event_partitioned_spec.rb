# frozen_string_literal: true

require 'spec_helper'

RSpec.describe AuditEventPartitioned, type: :model do
  let(:original_model) do
    Class.new(ActiveRecord::Base) do
      self.table_name = :audit_events
      self.inheritance_column = :_type_disabled
    end
  end

  # Added here to ensure that the schema of the audit_events table is not altered while the partitioning migration
  # is underway. If this test fails because you are attempting to alter the audit_events table, please contact the
  # database team for details about the ongoing partitioning effort.
  it 'stays in sync with the schema of the original AuditEvent model' do
    original_columns = original_model.columns.sort_by(&:name)
    partitioned_columns = described_class.columns.sort_by(&:name)

    expect(original_columns.size).to eq(partitioned_columns.size)

    expect_column_to_match(original_columns, partitioned_columns, 'id')

    expect_column_to_match(original_columns, partitioned_columns, 'created_at') do |original, partitioned|
      expect(original.sql_type).to eq(partitioned.sql_type)
    end

    partitioned_columns.zip(original_columns).each do |(partitioned, original)|
      expect(partitioned).to eq(original)
    end
  end

  def expect_column_to_match(original_columns, partitioned_columns, column_name)
    original_index = original_columns.index { |c| c.name == column_name}
    partitioned_index = partitioned_columns.index { |c| c.name == column_name }

    expect(original_index).not_to be_nil
    expect(original_index).to eq(partitioned_index)

    original_column = original_columns.delete_at(original_index)
    partitioned_column = partitioned_columns.delete_at(partitioned_index)

    yield original_column, partitioned_column if block_given?
  end
end
