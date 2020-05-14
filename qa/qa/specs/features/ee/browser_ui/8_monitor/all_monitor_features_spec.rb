# frozen_string_literal: true

module QA
  context 'Monitor', quarantine: { issue: 'https://gitlab.com/gitlab-org/gitlab/-/issues/217705', type: :flaky } do
    describe 'with Prometheus Gitlab-managed cluster', :orchestrated, :kubernetes, :docker, :runner do
      before :all do
        @cluster = Service::KubernetesCluster.new.create!
        Flow::Login.sign_in
        @project, @runner = deploy_project_with_prometheus
      end

      after :all do
        @runner&.remove_via_api!
        @cluster&.remove!
      end

      before do
        Flow::Login.sign_in_unless_signed_in
        @project.visit!
      end

      it 'allows configuration of alerts' do
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |metrics|
          verify_metrics(metrics)
          verify_add_alert(metrics)
          verify_edit_alert(metrics)
          verify_persist_alert(metrics)
          verify_delete_alert(metrics)
        end
      end

      it 'observes cluster health graph' do
        Page::Project::Menu.perform(&:go_to_operations_kubernetes)

        Page::Project::Operations::Kubernetes::Index.perform do |cluster|
          cluster.click_on_cluster(@cluster)
        end

        Page::Project::Operations::Kubernetes::Show.perform do |cluster|
          cluster.open_health

          cluster.wait_for_cluster_health
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
        project = Resource::Project.fabricate_via_api! do |project|
          project.name = 'cluster-with-prometheus'
          project.description = 'Cluster with Prometheus'
        end

        runner = Resource::Runner.fabricate_via_api! do |runner|
          runner.project = project
          runner.name = project.name
        end

        cluster_props = Resource::KubernetesCluster::ProjectCluster.fabricate! do |cluster|
          cluster.project = project
          cluster.cluster = @cluster
          cluster.install_helm_tiller = true
          cluster.install_ingress = true
          cluster.install_prometheus = true
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.directory = Pathname
                               .new(__dir__)
                               .join('../../../../../fixtures/monitored_auto_devops')
          push.commit_message = 'Create AutoDevOps compatible Project for Monitoring'
        end

        Resource::CiVariable.fabricate_via_api! do |ci_variable|
          ci_variable.project = project
          ci_variable.key = 'AUTO_DEVOPS_DOMAIN'
          ci_variable.value = cluster_props.ingress_ip
          ci_variable.masked = false
        end

        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_success_or_retry)

        [project, runner]
      end

      def verify_metrics(metrics)
        metrics.wait_for_metrics

        expect(metrics).to have_metrics
        expect(metrics).not_to have_alert
      end

      def verify_add_alert(metrics)
        metrics.write_first_alert('>', 0)

        expect(metrics).to have_alert
      end

      def verify_edit_alert(metrics)
        metrics.write_first_alert('<', 0)

        expect(metrics).to have_alert('<')
      end

      def verify_persist_alert(metrics)
        metrics.refresh
        metrics.wait_for_metrics
        metrics.wait_for_alert('<')

        expect(metrics).to have_alert('<')
      end

      def verify_delete_alert(metrics)
        metrics.delete_first_alert

        expect(metrics).not_to have_alert('<')
      end

      def create_incident_template
        Page::Project::Menu.perform(&:go_to_operations_metrics)

        @chart_link = Page::Project::Operations::Metrics::Show.perform do |metric|
          metric.wait_for_metrics
          metric.copy_link_to_first_chart
        end

        incident_template = "Incident Metric: #{@chart_link}"
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
