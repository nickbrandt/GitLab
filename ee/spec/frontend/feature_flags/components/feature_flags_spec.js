import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import featureFlagsComponent from 'ee/feature_flags/components/feature_flags.vue';
import mountComponent from 'helpers/vue_mount_component_helper';
import { trimText } from 'helpers/text_helper';
import { TEST_HOST } from 'spec/test_constants';
import { getRequestData } from '../mock_data';

describe('Feature flags', () => {
  const mockData = {
    endpoint: `${TEST_HOST}/endpoint.json`,
    csrfToken: 'testToken',
    errorStateSvgPath: '/assets/illustrations/feature_flag.svg',
    featureFlagsHelpPagePath: '/help/feature-flags',
    featureFlagsAnchoredHelpPagePath: '/help/feature-flags#unleash-clients',
    unleashApiUrl: `${TEST_HOST}/api/unleash`,
    unleashApiInstanceId: 'oP6sCNRqtRHmpy1gw2-F',
    canUserConfigure: true,
    canUserRotateToken: true,
    newFeatureFlagPath: 'feature-flags/new',
  };

  let FeatureFlagsComponent;
  let component;
  let mock;

  beforeEach(() => {
    mock = new MockAdapter(axios);

    FeatureFlagsComponent = Vue.extend(featureFlagsComponent);
  });

  afterEach(() => {
    mock.restore();
    component.$destroy();
  });

  describe('without permissions', () => {
    const props = {
      endpoint: `${TEST_HOST}/endpoint.json`,
      csrfToken: 'testToken',
      errorStateSvgPath: '/assets/illustrations/feature_flag.svg',
      featureFlagsHelpPagePath: '/help/feature-flags',
      canUserConfigure: false,
      canUserRotateToken: false,
      featureFlagsAnchoredHelpPagePath: '/help/feature-flags#unleash-clients',
      unleashApiUrl: `${TEST_HOST}/api/unleash`,
      unleashApiInstanceId: 'oP6sCNRqtRHmpy1gw2-F',
    };

    beforeEach(done => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: 'all', page: '1' } })
        .reply(200, getRequestData, {});

      component = mountComponent(FeatureFlagsComponent, props);

      setImmediate(() => {
        done();
      });
    });

    it('does not render configure button', () => {
      expect(component.$el.querySelector('.js-ff-configure')).toBeNull();
    });

    it('does not render new feature flag button', () => {
      expect(component.$el.querySelector('.js-ff-new')).toBeNull();
    });
  });

  describe('loading state', () => {
    it('renders a loading icon', () => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: 'all', page: '1' } })
        .replyOnce(200, getRequestData, {});

      component = mountComponent(FeatureFlagsComponent, mockData);

      const loadingElement = component.$el.querySelector('.js-loading-state');

      expect(loadingElement).not.toBeNull();
      expect(loadingElement.querySelector('span').getAttribute('aria-label')).toEqual(
        'Loading feature flags',
      );
    });
  });

  describe('successful request', () => {
    describe('without feature flags', () => {
      beforeEach(done => {
        mock.onGet(mockData.endpoint, { params: { scope: 'all', page: '1' } }).replyOnce(
          200,
          {
            feature_flags: [],
            count: {
              all: 0,
              enabled: 0,
              disabled: 0,
            },
          },
          {},
        );

        component = mountComponent(FeatureFlagsComponent, mockData);

        setImmediate(() => {
          done();
        });
      });

      it('should render the empty state', () => {
        expect(component.$el.querySelector('.js-feature-flags-empty-state')).not.toBeNull();
      });

      it('renders configure button', () => {
        expect(component.$el.querySelector('.js-ff-configure')).not.toBeNull();
      });

      it('renders new feature flag button', () => {
        expect(component.$el.querySelector('.js-ff-new')).not.toBeNull();
      });

      describe('in all tab', () => {
        it('renders generic title', () => {
          expect(
            component.$el.querySelector('.js-feature-flags-empty-state h4').textContent.trim(),
          ).toEqual('Get started with feature flags');
        });
      });

      describe('in disabled tab', () => {
        it('renders disabled title', done => {
          component.scope = 'disabled';

          Vue.nextTick(() => {
            expect(
              component.$el.querySelector('.js-feature-flags-empty-state h4').textContent.trim(),
            ).toEqual('There are no inactive feature flags');
            done();
          });
        });
      });

      describe('in enabled tab', () => {
        it('renders enabled title', done => {
          component.scope = 'enabled';

          Vue.nextTick(() => {
            expect(
              component.$el.querySelector('.js-feature-flags-empty-state h4').textContent.trim(),
            ).toEqual('There are no active feature flags');
            done();
          });
        });
      });
    });

    describe('with paginated feature flags', () => {
      beforeEach(done => {
        mock
          .onGet(mockData.endpoint, { params: { scope: 'all', page: '1' } })
          .replyOnce(200, getRequestData, {
            'x-next-page': '2',
            'x-page': '1',
            'X-Per-Page': '2',
            'X-Prev-Page': '',
            'X-TOTAL': '37',
            'X-Total-Pages': '5',
          });

        component = mountComponent(FeatureFlagsComponent, mockData);
        setImmediate(() => {
          done();
        });
      });

      it('should render a table with feature flags', () => {
        expect(component.$el.querySelectorAll('.js-feature-flag-table')).not.toBeNull();
        expect(component.$el.querySelector('.feature-flag-name').textContent.trim()).toEqual(
          getRequestData.feature_flags[0].name,
        );

        expect(component.$el.querySelector('.feature-flag-description').textContent.trim()).toEqual(
          getRequestData.feature_flags[0].description,
        );
      });

      it('renders configure button', () => {
        expect(component.$el.querySelector('.js-ff-configure')).not.toBeNull();
      });

      it('renders new feature flag button', () => {
        expect(component.$el.querySelector('.js-ff-new')).not.toBeNull();
      });

      describe('pagination', () => {
        it('should render pagination', () => {
          expect(component.$el.querySelectorAll('.gl-pagination')).not.toBeNull();
        });

        it('should make an API request when page is clicked', () => {
          jest.spyOn(component, 'updateFeatureFlagOptions');
          component.$el.querySelector('.gl-pagination li:nth-child(5) .page-link').click();

          expect(component.updateFeatureFlagOptions).toHaveBeenCalledWith({
            scope: 'all',
            page: '4',
          });
        });

        it('should make an API request when using tabs', () => {
          jest.spyOn(component, 'updateFeatureFlagOptions');
          component.$el.querySelector('.js-featureflags-tab-enabled').click();

          expect(component.updateFeatureFlagOptions).toHaveBeenCalledWith({
            scope: 'enabled',
            page: '1',
          });
        });
      });
    });
  });

  describe('unsuccessful request', () => {
    beforeEach(done => {
      mock.onGet(mockData.endpoint, { params: { scope: 'all', page: '1' } }).replyOnce(500, {});

      component = mountComponent(FeatureFlagsComponent, mockData);

      setImmediate(() => {
        done();
      });
    });

    it('should render error state', () => {
      expect(trimText(component.$el.querySelector('.empty-state').textContent)).toContain(
        'There was an error fetching the feature flags. Try again in a few moments or contact your support team.',
      );
    });

    it('renders configure button', () => {
      expect(component.$el.querySelector('.js-ff-configure')).not.toBeNull();
    });

    it('renders new feature flag button', () => {
      expect(component.$el.querySelector('.js-ff-new')).not.toBeNull();
    });
  });

  describe('rotate instance id', () => {
    beforeEach(done => {
      component = mountComponent(FeatureFlagsComponent, mockData);

      setImmediate(() => {
        done();
      });
    });

    it('should fire the rotate action when a `token` event is received', () => {
      const actionSpy = jest.spyOn(component, 'rotateInstanceId');
      const [modal] = component.$children;
      modal.$emit('token');

      expect(actionSpy).toHaveBeenCalled();
    });
  });
});
