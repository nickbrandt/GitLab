# frozen_string_literal: true

RSpec.shared_context 'background migration job class' do
  let!(:job_class_name) { 'TestJob' }
  let!(:job_class) { Class.new }
  let!(:job_perform_method) do
    ->(*arguments) do
      Gitlab::Database::BackgroundMigrationJob.mark_all_as_succeeded(
        # 'TestJob' define in :job_class_name by let! above.
        RSpec.current_example.example_group_instance.job_class_name,
        arguments
      )
    end
  end

  before do
    job_class.define_method(:perform, job_perform_method)
    expect(Gitlab::BackgroundMigration).to receive(:migration_class_for).with(job_class_name).at_least(:once) { job_class }
  end
end
