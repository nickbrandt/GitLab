# frozen_string_literal: true

module QA
  context 'Monitor' do
    describe 'Alerts', :orchestrated, :kubernetes do
      before do
        @cluster = Service::KubernetesCluster.new.create!
      end

      after do
        @cluster&.remove!
      end

      it 'allows configuration of alerts' do
        Flow::Login.sign_in
        project = create_project
        create_kubernetes_cluster(project, @cluster)
        push_repository(project)
        wait_for_deployment

        Page::Project::Operations::Metrics::Show.perform do |metrics|
          verify_metrics(metrics)
          verify_add_alert(metrics)
          verify_edit_alert(metrics)
          verify_persist_alert(metrics)
          verify_delete_alert(metrics)
        end
      end

      private

      def create_project
        Resource::Project.fabricate_via_api! do |p|
          p.name = 'alerts'
          p.description = 'Project with alerting configured'
        end
      end

      def create_kubernetes_cluster(project, cluster)
        Resource::KubernetesCluster::ProjectCluster.fabricate_via_browser_ui! do |c|
          c.project = project
          c.cluster = cluster
          c.install_helm_tiller = true
          c.install_prometheus = true
          c.install_runner = true
        end
      end

      def push_repository(project)
        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = project
          push.directory = Pathname
            .new(__dir__)
            .join('../../../../../../fixtures/monitored_auto_devops')
          push.commit_message = 'Create Auto DevOps compatible gitlab-ci.yml'
        end

        Resource::CiVariable.fabricate_via_api! do |resource|
          resource.project = project
          resource.key = 'AUTO_DEVOPS_DOMAIN'
          resource.value = 'my-fake-domain.com'
          resource.masked = false
        end
      end

      def wait_for_deployment
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_success_or_retry)
        Page::Project::Menu.perform(&:go_to_operations_metrics)
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
    end
  end
end
