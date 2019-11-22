# frozen_string_literal: true

module QA
  context 'Monitor' do
    describe 'Cluster health graphs', :orchestrated, :kubernetes do
      before do
        @cluster = Service::KubernetesCluster.new.create!
      end

      after do
        @cluster&.remove!
      end

      it 'installs Kubernetes and Prometheus' do
        Flow::Login.sign_in

        create_project

        create_kubernetes_cluster

        verify_cluster_health_graphs
      end

      private

      def create_project
        @project = Resource::Project.fabricate_via_api! do |p|
          p.name = 'cluster-health'
          p.description = 'Cluster health'
        end
      end

      def create_kubernetes_cluster
        Resource::KubernetesCluster.fabricate_via_browser_ui! do |c|
          c.project = @project
          c.cluster = @cluster
          c.install_helm_tiller = true
          c.install_prometheus = true
        end
      end

      def verify_cluster_health_graphs
        Page::Project::Operations::Kubernetes::Show.perform do |cluster|
          cluster.refresh
          expect(cluster).to have_cluster_health_title

          cluster.wait_for_cluster_health
        end
      end
    end
  end
end
