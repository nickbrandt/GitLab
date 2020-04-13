# frozen_string_literal: true

shared_context 'Pipeline Processing Service Tests With Yaml' do
  where(:test_file_path) do
    Dir.glob(Rails.root.join('spec/services/ci/pipeline_processing/test_cases/*.yml'))
  end

  with_them do
    include_context 'execute pipeline processing test case'
  end
end

shared_context 'execute pipeline processing test case' do
  let(:user) { create(:user) }
  let(:project) { create(:project, :repository) }

  let(:test_file) { YAML.load_file(test_file_path) }

  before do
    stub_ci_pipeline_yaml_file(YAML.dump(test_file['config']))
    stub_not_protect_default_branch
    project.add_developer(user)
  end

  let!(:pipeline) { Ci::CreatePipelineService.new(project, user, ref: 'master').execute(:pipeline) }

  it 'follows transitions', :sidekiq_inline do
    test_file['transitions'].each do |transition|
      case transition['event']
      when 'start'
        expect(pipeline).to be_persisted
        check_expectation(transition['expect'])
      when 'play'
        play_jobs(transition['jobs'])
        check_expectation(transition['expect'])
      when 'run', 'success', 'drop'
        event_on_jobs(transition['event'], transition['jobs'])
        check_expectation(transition['expect'])
      else
        raise "invalid transition event: #{transition['event']}"
      end
    end
  end

  private

  def check_expectation(expectation)
    expectation.each do |key, value|
      case key
      when 'pipeline'
        expect(pipeline.reload.status).to eq(value)
      when 'stages'
        value.each do |name, status|
          expect(stage_by_name(name).status).to eq(status)
        end
      when 'jobs'
        value.each do |name, status|
          expect(build_by_name(name).status).to eq(status)
        end
      end
    end
  end

  def play_jobs(job_names)
    job_names.each do |job_name|
      build_by_name(job_name).play(user)
    end
  end

  def event_on_jobs(event, job_names)
    job_names.each do |job_name|
      build_by_name(job_name).public_send("#{event}!")
    end
  end

  def stage_by_name(name)
    pipeline.stages.find_by!(name: name)
  end

  def build_by_name(name)
    pipeline.builds.find_by!(name: name)
  end
end
