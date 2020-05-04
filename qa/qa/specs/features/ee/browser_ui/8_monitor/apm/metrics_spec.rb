# frozen_string_literal: true

module QA
  context 'Monitor' do
    describe 'Metrics with Prometheus', :orchestrated, :kubernetes, quarantine: { type: :new } do
      before do
        @cluster = Service::KubernetesCluster.new.create!
        Flow::Login.sign_in
        create_project_to_monitor
        wait_for_deployment
      end

      after do
        @cluster&.remove!
      end

      it 'configures custom metrics in Prometheus running on a Kubernetes cluster' do
        Page::Project::Operations::Metrics::Show.perform do |metrics|
          metrics.add_custom_metric
        end

        Page::Project::Menu.perform(&:go_to_operations_metrics)

        Page::Project::Operations::Metrics::Show.perform do |metrics|
          expect(metrics).to have_custom_metric
        end
      end

      private

      def wait_for_deployment
        Page::Project::Menu.perform(&:click_ci_cd_pipelines)
        Page::Project::Pipeline::Index.perform(&:wait_for_latest_pipeline_success_or_retry)
        Page::Project::Menu.perform(&:go_to_operations_metrics)
      end

      def create_project_to_monitor
        @project = Resource::Project.fabricate_via_api! do |p|
          p.name = 'cluster-with-prometheus'
          p.description = 'Cluster with Prometheus'
        end

        @cluster_props = Resource::KubernetesCluster::ProjectCluster.fabricate_via_browser_ui! do |c|
          c.project = @project
          c.cluster = @cluster
          c.install_helm_tiller = true
          c.install_prometheus = true
          c.install_ingress = true
        end

        Resource::CiVariable.fabricate_via_api! do |resource|
          resource.project = @project
          resource.key = 'AUTO_DEVOPS_DOMAIN'
          resource.value = @cluster_props.ingress_ip
          resource.masked = false
        end

        Resource::Repository::ProjectPush.fabricate! do |push|
          push.project = @project
          push.directory = Pathname
                               .new(__dir__)
                               .join('../../../../../../fixtures/monitored_auto_devops')
          push.commit_message = 'Create AutoDevOps compatible Project for Monitoring'
        end
      end
    end
  end
end
