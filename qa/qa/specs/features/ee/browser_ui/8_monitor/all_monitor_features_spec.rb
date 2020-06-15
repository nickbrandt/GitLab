# frozen_string_literal: true
require 'pathname'

module QA
  context 'Monitor' do
    describe 'with Prometheus in a Gitlab-managed cluster', :orchestrated, :kubernetes do
      before :all do
        @cluster = Service::KubernetesCluster.new.create!
        @project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'monitoring-project'
          project.auto_devops_enabled = true
        end

        deploy_project_with_prometheus
      end

      after :all do
        @cluster.remove!
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
      end

      it 'allows configuration of alerts' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          verify_metrics(on_dashboard)
          verify_add_alert(on_dashboard)
          verify_edit_alert(on_dashboard)
          verify_persist_alert(on_dashboard)
          verify_delete_alert(on_dashboard)
        end
      end

      it 'observes cluster health graph' do
        Page::Project::Menu.perform(&:go_to_operations_kubernetes)

        Page::Project::Operations::Kubernetes::Index.perform do |cluster_list|
          cluster_list.click_on_cluster(@cluster)
        end

        Page::Project::Operations::Kubernetes::Show.perform do |cluster_panel|
          cluster_panel.open_health
          cluster_panel.wait_for_cluster_health
        end
      end

      it 'creates and sets an incident template' do
        create_incident_template

        Page::Project::Menu.perform(&:go_to_operations_settings)

        Page::Project::Settings::Operations.perform do |settings|
          settings.expand_incidents do |incident_settings|
            incident_settings.enable_issues_for_incidents
            incident_settings.select_issue_template('incident')
            incident_settings.save_incident_settings
          end
          settings.expand_incidents do |incident_settings|
            expect(incident_settings).to have_template('incident')
          end
        end
      end

      private

      def deploy_project_with_prometheus
        %w[
          CODE_QUALITY_DISABLED TEST_DISABLED LICENSE_MANAGEMENT_DISABLED
          SAST_DISABLED DAST_DISABLED DEPENDENCY_SCANNING_DISABLED
          CONTAINER_SCANNING_DISABLED PERFORMANCE_DISABLED
        ].each do |key|
          Resource::CiVariable.fabricate_via_api! do |resource|
            resource.project = @project
            resource.key = key
            resource.value = '1'
            resource.masked = false
          end
        end

        Flow::Login.sign_in

        Resource::KubernetesCluster::ProjectCluster.fabricate! do |cluster_settings|
          cluster_settings.project = @project
          cluster_settings.cluster = @cluster
          cluster_settings.install_helm_tiller = true
          cluster_settings.install_runner = true
          cluster_settings.install_ingress = true
          cluster_settings.install_prometheus = true
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
                               .new(__dir__)
                               .join('../../../../../fixtures/auto_devops_rack')
          push.commit_message = 'Create AutoDevOps compatible Project for Monitoring'
        end

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:click_on_latest_pipeline)

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('build')
        end
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 600)

          job.click_element(:pipeline_path)
        end

        Page::Project::Pipeline::Show.perform do |pipeline|
          pipeline.click_job('production')
        end
        Page::Project::Job::Show.perform do |job|
          expect(job).to be_successful(timeout: 1200)

          job.click_element(:pipeline_path)
        end
      end

      def verify_metrics(on_dashboard)
        on_dashboard.wait_for_metrics

        expect(on_dashboard).to have_metrics
        expect(on_dashboard).not_to have_alert
      end

      def verify_add_alert(on_dashboard)
        on_dashboard.write_first_alert('>', 0)

        expect(on_dashboard).to have_alert
      end

      def verify_edit_alert(on_dashboard)
        on_dashboard.write_first_alert('<', 0)

        expect(on_dashboard).to have_alert('<')
      end

      def verify_persist_alert(on_dashboard)
        on_dashboard.refresh
        on_dashboard.wait_for_metrics
        on_dashboard.wait_for_alert('<')

        expect(on_dashboard).to have_alert('<')
      end

      def verify_delete_alert(on_dashboard)
        on_dashboard.delete_first_alert

        expect(on_dashboard).not_to have_alert('<')
      end

      def create_incident_template
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        chart_link = Page::Project::Operations::Metrics::Show.perform do |on_dashboard|
          on_dashboard.wait_for_metrics
          on_dashboard.copy_link_to_first_chart
        end

        incident_template = "Incident Metric: #{chart_link}"
        push_template_to_repository(incident_template)
      end

      def push_template_to_repository(template)
        @project.visit!

        Page::Project::Show.perform(&:create_new_file!)

        Page::File::Form.perform do |form|
          form.add_name('.gitlab/issue_templates/incident.md')
          form.add_content(template)
          form.add_commit_message('Add Incident template')
          form.commit_changes
        end
      end
    end
  end
end
