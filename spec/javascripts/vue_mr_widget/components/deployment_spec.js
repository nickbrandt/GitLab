import Vue from 'vue';
import deploymentComponent from '~/vue_merge_request_widget/components/deployment.vue';
import MRWidgetService from '~/vue_merge_request_widget/services/mr_widget_service';
import { getTimeago } from '~/lib/utils/datetime_utility';
import mountComponent from '../../helpers/vue_mount_component_helper';

describe('Deployment component', () => {
  const Component = Vue.extend(deploymentComponent);
  let deploymentMockData;

  beforeEach(() => {
    deploymentMockData = {
      id: 15,
      name: 'review/diplo',
      url: '/root/review-apps/environments/15',
      stop_url: '/root/review-apps/environments/15/stop',
      metrics_url: '/root/review-apps/environments/15/deployments/1/metrics',
      metrics_monitoring_url: '/root/review-apps/environments/15/metrics',
      external_url: 'http://gitlab.com.',
      external_url_formatted: 'gitlab',
      deployed_at: '2017-03-22T22:44:42.258Z',
      deployed_at_formatted: 'Mar 22, 2017 10:44pm',
      deployment_manual_actions: [],
      status: 'success',
      changes: [
        {
          path: 'index.html',
          external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/index.html',
        },
        {
          path: 'imgs/gallery.html',
          external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/imgs/gallery.html',
        },
        {
          path: 'about/',
          external_url: 'http://root-master-patch-91341.volatile-watch.surge.sh/about/',
        },
      ],
    };
  });

  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('', () => {
    beforeEach((done) => {
      vm = mountComponent(Component, { deployment: { ...deploymentMockData }, showMetrics: true });
      Vue.nextTick(done);
    });

    describe('hasExternalUrls', () => {
      it('should return true', () => {
        expect(vm.hasExternalUrls).toEqual(true);
      });

      it('should return false when deployment has no external_url_formatted', () => {
        vm.deployment.external_url_formatted = null;

        expect(vm.hasExternalUrls).toEqual(false);
      });

      it('should return false when deployment has no external_url', () => {
        vm.deployment.external_url = null;

        expect(vm.hasExternalUrls).toEqual(false);
      });
    });

    it('renders deployment name', () => {
      expect(vm.$el.querySelector('.js-deploy-meta').getAttribute('href')).toEqual(
        deploymentMockData.url,
      );

      expect(vm.$el.querySelector('.js-deploy-meta').innerText).toContain(deploymentMockData.name);
    });

    it('renders external URL', () => {
      expect(vm.$el.querySelector('.js-deploy-url').getAttribute('href')).toEqual(
        deploymentMockData.external_url,
      );

      expect(vm.$el.querySelector('.js-deploy-url').innerText).toContain('View app');
    });

    it('renders stop button', () => {
      expect(vm.$el.querySelector('.btn')).not.toBeNull();
    });

    it('renders metrics component', () => {
      expect(vm.$el.querySelector('.js-mr-memory-usage')).not.toBeNull();
    });
  });

  describe('with showMetrics enabled', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { deployment: { ...deploymentMockData }, showMetrics: true });
    });

    it('shows metrics', () => {
      expect(vm.$el).toContainElement('.js-mr-memory-usage');
    });
  });

  describe('with showMetrics disabled', () => {
    beforeEach(() => {
      vm = mountComponent(Component, { deployment: { ...deploymentMockData }, showMetrics: false });
    });

    it('hides metrics', () => {
      expect(vm.$el).not.toContainElement('.js-mr-memory-usage');
    });
  });

  describe('without changes', () => {
    beforeEach(() => {
      delete deploymentMockData.changes;

      vm = mountComponent(Component, { deployment: { ...deploymentMockData }, showMetrics: true });
    });

    it('renders the link to the review app without dropdown', () => {
      expect(vm.$el.querySelector('.js-mr-wigdet-deployment-dropdown')).toBeNull();
      expect(vm.$el.querySelector('.js-deploy-url')).not.toBeNull();
    });
  });

  describe('with a single change', () => {
    beforeEach(() => {
      deploymentMockData.changes = deploymentMockData.changes.slice(0, 1);

      vm = mountComponent(Component, {
        deployment: { ...deploymentMockData },
        showMetrics: true,
      });
    });

    it('renders the link to the review app without dropdown', () => {
      expect(vm.$el.querySelector('.js-mr-wigdet-deployment-dropdown')).toBeNull();
      expect(vm.$el.querySelector('.js-deploy-url')).not.toBeNull();
    });

    it('renders the link to the review app linked to to the first change', () => {
      const expectedUrl = deploymentMockData.changes[0].external_url;
      const deployUrl = vm.$el.querySelector('.js-deploy-url');

      expect(vm.$el.querySelector('.js-mr-wigdet-deployment-dropdown')).toBeNull();
      expect(deployUrl).not.toBeNull();
      expect(deployUrl.href).toEqual(expectedUrl);
    });
  });

  describe('deployment status', () => {
    describe('running', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'running' }),
          showMetrics: true,
        });
      });

      it('renders information about running deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain('Deploying to');
      });

      it('renders disabled stop button', () => {
        expect(vm.$el.querySelector('.js-stop-env').getAttribute('disabled')).toBe('disabled');
      });
    });

    describe('success', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'success' }),
          showMetrics: true,
        });
      });

      it('renders information about finished deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain('Deployed to');
      });
    });

    describe('failed', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'failed' }),
          showMetrics: true,
        });
      });

      it('renders information about finished deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain(
          'Failed to deploy to',
        );
      });
    });

    describe('created', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'created' }),
          showMetrics: true,
        });
      });

      it('renders information about created deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain('Will deploy to');
      });
    });

    describe('canceled', () => {
      beforeEach(() => {
        vm = mountComponent(Component, {
          deployment: Object.assign({}, deploymentMockData, { status: 'canceled' }),
          showMetrics: true,
        });
      });

      it('renders information about canceled deployment', () => {
        expect(vm.$el.querySelector('.js-deployment-info').textContent).toContain(
          'Canceled deploy to',
        );
      });
    });
  });
});
