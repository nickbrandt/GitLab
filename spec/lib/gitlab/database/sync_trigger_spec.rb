# frozen_string_literal: true

require 'spec_helper'

RSpec.describe Gitlab::Database::SyncTrigger do
  include TriggerHelpers
  include SchemaCommentHelpers

  let(:source_table_name) { :_test_source_table }
  let(:destination_table_name) { :_test_destination_table }
  let(:function_name) { '_test_sync_function' }
  let(:trigger_name) { '_test_sync_trigger' }
  let(:logger) { double('logger') }
  let(:connection) { ActiveRecord::Base.connection }

  let(:sync_trigger) { described_class.for_table(source_table_name, message_context: 'Test', logger: logger) }

  before do
    connection.execute(<<~SQL)
      CREATE TABLE #{source_table_name} (
        id serial NOT NULL PRIMARY KEY,
        name text NOT NULL,
        created_at timestamptz NOT NULL,
        updated_at timestamptz NOT NULL);

      CREATE TABLE #{destination_table_name} (LIKE _test_source_table);
    SQL

    allow(sync_trigger).to receive(:function_name).and_return(function_name)
    allow(sync_trigger).to receive(:trigger_name).and_return(trigger_name)
  end

  describe '#create' do
    context 'the trigger and function do not exist' do
      let(:source_model) { Class.new(ActiveRecord::Base) }
      let(:destination_model) { Class.new(ActiveRecord::Base) }
      let(:timestamp) { Time.utc(2020, 1, 1, 12).round }

      before do
        source_model.table_name = source_table_name
        destination_model.table_name = destination_table_name
      end

      it 'creates the function trigger to fire on all writes' do
        expect_function_not_to_exist(function_name)
        expect_trigger_not_to_exist(source_table_name, trigger_name)

        sync_trigger.create(destination_table_name, :id)

        expect_function_to_exist(function_name)
        expect_function_to_have_comment(function_name, "Test: table sync for #{source_table_name} table")
        expect_valid_function_trigger(source_table_name, trigger_name, function_name, after: %w[delete insert update])
      end

      it 'creates a valid function that copies all values' do
        sync_trigger.create(destination_table_name, :id)

        expect(destination_model.count).to eq(0)

        source_record = source_model.create!(name: 'Bob', created_at: timestamp, updated_at: timestamp)

        expect(destination_model.count).to eq(1)
        expect(destination_model.first).to have_attributes(source_record.attributes)

        source_record.update!(name: 'Sam', updated_at: timestamp + 1.hour)

        expect(destination_model.count).to eq(1)
        expect(destination_model.first).to have_attributes(source_record.attributes)

        source_record.destroy!

        expect(destination_model.count).to eq(0)
      end
    end

    context 'the function already exists' do
      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}()
          RETURNS TRIGGER AS
          $$
          BEGIN
          RAISE NOTICE 'hi';
          END
          $$ LANGUAGE PLPGSQL;
        SQL

        allow(logger).to receive(:warn)
      end

      it 'logs a warning' do
        expect(logger).to receive(:warn).with(/Test sync function not created/)

        sync_trigger.create(destination_table_name, :id)
      end

      it 'creates the trigger to call the function' do
        expect_function_to_exist(function_name)
        expect_trigger_not_to_exist(source_table_name, trigger_name)

        sync_trigger.create(destination_table_name, :id)

        expect_function_to_exist(function_name)
        expect_valid_function_trigger(source_table_name, trigger_name, function_name, after: %w[delete insert update])
      end
    end

    context 'the trigger already exists' do
      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}()
          RETURNS TRIGGER AS
          $$
          BEGIN
          RAISE NOTICE 'hi';
          END
          $$ LANGUAGE PLPGSQL;

          CREATE TRIGGER #{trigger_name}
          AFTER INSERT OR UPDATE OR DELETE
          ON #{source_table_name}
          FOR EACH ROW EXECUTE FUNCTION #{function_name}();
        SQL

        allow(logger).to receive(:warn)
      end

      it 'logs a warning' do
        expect(logger).to receive(:warn).with(/Test sync trigger not created/)

        sync_trigger.create(destination_table_name, :id)
      end

      it 'leaves the existing trigger in place' do
        expect_function_to_exist(function_name)
        expect_valid_function_trigger(source_table_name, trigger_name, function_name, after: %w[delete insert update])

        sync_trigger.create(destination_table_name, :id)

        expect_function_to_exist(function_name)
        expect_valid_function_trigger(source_table_name, trigger_name, function_name, after: %w[delete insert update])
      end
    end
  end

  describe '#drop' do
    context 'the trigger and function exist' do
      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}()
          RETURNS TRIGGER AS
          $$
          BEGIN
          RAISE NOTICE 'hi';
          END
          $$ LANGUAGE PLPGSQL;

          CREATE TRIGGER #{trigger_name}
          AFTER INSERT OR UPDATE OR DELETE
          ON #{source_table_name}
          FOR EACH ROW EXECUTE FUNCTION #{function_name}();
        SQL

        allow(logger).to receive(:warn)
      end

      it 'drops the function and trigger on the source table' do
        expect_function_to_exist(function_name)
        expect_valid_function_trigger(source_table_name, trigger_name, function_name, after: %w[delete insert update])

        sync_trigger.drop

        expect_function_not_to_exist(function_name)
        expect_trigger_not_to_exist(source_table_name, trigger_name)
      end
    end

    context 'the trigger does not exist' do
      before do
        connection.execute(<<~SQL)
          CREATE FUNCTION #{function_name}()
          RETURNS TRIGGER AS
          $$
          BEGIN
          RAISE NOTICE 'hi';
          END
          $$ LANGUAGE PLPGSQL;
        SQL

        allow(logger).to receive(:warn)
      end

      it 'logs a warning' do
        expect(logger).to receive(:warn).with(/Test sync trigger not dropped/)

        sync_trigger.drop
      end

      it 'drops the function' do
        expect_function_to_exist(function_name)
        expect_trigger_not_to_exist(source_table_name, trigger_name)

        sync_trigger.drop

        expect_function_not_to_exist(function_name)
        expect_trigger_not_to_exist(source_table_name, trigger_name)
      end
    end

    context 'the trigger and function do not exist' do
      before do
        allow(logger).to receive(:warn)
      end

      it 'logs warnings' do
        expect(logger).to receive(:warn).with(/Test sync trigger not dropped/).ordered
        expect(logger).to receive(:warn).with(/Test sync function not dropped/).ordered

        sync_trigger.drop
      end

      it 'leaves the current state intact' do
        expect_function_not_to_exist(function_name)
        expect_trigger_not_to_exist(source_table_name, trigger_name)

        sync_trigger.drop

        expect_function_not_to_exist(function_name)
        expect_trigger_not_to_exist(source_table_name, trigger_name)
      end
    end
  end
end
