import { shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import store from 'ee/feature_flags/store';
import FeatureFlagsComponent from 'ee/feature_flags/components/feature_flags.vue';
import FeatureFlagsTable from 'ee/feature_flags/components/feature_flags_table.vue';
import ConfigureFeatureFlagsModal from 'ee/feature_flags/components/configure_feature_flags_modal.vue';
import { TEST_HOST } from 'spec/test_constants';
import NavigationTabs from '~/vue_shared/components/navigation_tabs';
import TablePagination from '~/vue_shared/components/pagination/table_pagination.vue';
import axios from '~/lib/utils/axios_utils';
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

  let wrapper;
  let mock;

  const factory = (propsData = mockData) => {
    wrapper = shallowMount(FeatureFlagsComponent, {
      propsData,
      sync: false,
    });
  };

  const configureButton = () => wrapper.find('.js-ff-configure');
  const newButton = () => wrapper.find('.js-ff-new');

  beforeEach(() => {
    mock = new MockAdapter(axios);
    jest.spyOn(store, 'dispatch');
  });

  afterEach(() => {
    mock.restore();
    wrapper.destroy();
  });

  describe('without permissions', () => {
    const propsData = {
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

      factory(propsData);

      setImmediate(() => {
        done();
      });
    });

    it('does not render configure button', () => {
      expect(configureButton().exists()).toBe(false);
    });

    it('does not render new feature flag button', () => {
      expect(newButton().exists()).toBe(false);
    });
  });

  describe('loading state', () => {
    it('renders a loading icon', () => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: 'all', page: '1' } })
        .replyOnce(200, getRequestData, {});

      factory();

      const loadingElement = wrapper.find(GlLoadingIcon);

      expect(loadingElement.exists()).toBe(true);
      expect(loadingElement.props('label')).toEqual('Loading feature flags');
    });
  });

  describe('successful request', () => {
    describe('without feature flags', () => {
      let emptyState;

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

        factory();

        setImmediate(() => {
          emptyState = wrapper.find(GlEmptyState);
          done();
        });
      });

      it('should render the empty state', () => {
        expect(wrapper.find(GlEmptyState).exists()).toBe(true);
      });

      it('renders configure button', () => {
        expect(configureButton().exists()).toBe(true);
      });

      it('renders new feature flag button', () => {
        expect(newButton().exists()).toBe(true);
      });

      describe('in all tab', () => {
        it('renders generic title', () => {
          expect(emptyState.props('title')).toEqual('Get started with feature flags');
        });
      });

      describe('in disabled tab', () => {
        it('renders disabled title', () => {
          wrapper.setData({ scope: 'disabled' });

          return wrapper.vm.$nextTick(() => {
            expect(emptyState.props('title')).toEqual('There are no inactive feature flags');
          });
        });
      });

      describe('in enabled tab', () => {
        it('renders enabled title', () => {
          wrapper.setData({ scope: 'enabled' });

          wrapper.vm.$nextTick(() => {
            expect(emptyState.props('title')).toEqual('There are no active feature flags');
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

        factory();
        setImmediate(() => {
          done();
        });
      });

      it('should render a table with feature flags', () => {
        const table = wrapper.find(FeatureFlagsTable);
        expect(table.exists()).toBe(true);
        expect(table.props('featureFlags')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              name: getRequestData.feature_flags[0].name,
              description: getRequestData.feature_flags[0].description,
            }),
          ]),
        );
      });

      it('should toggle a flag when receiving the toggle-flag event', () => {
        const table = wrapper.find(FeatureFlagsTable);

        const [flag] = table.props('featureFlags');
        table.vm.$emit('toggle-flag', flag);

        expect(store.dispatch).toHaveBeenCalledWith('index/toggleFeatureFlag', flag);
      });

      it('renders configure button', () => {
        expect(configureButton().exists()).toBe(true);
      });

      it('renders new feature flag button', () => {
        expect(newButton().exists()).toBe(true);
      });

      describe('pagination', () => {
        it('should render pagination', () => {
          expect(wrapper.find(TablePagination).exists()).toBe(true);
        });

        it('should make an API request when page is clicked', () => {
          jest.spyOn(wrapper.vm, 'updateFeatureFlagOptions');
          wrapper.find(TablePagination).vm.change(4);

          expect(wrapper.vm.updateFeatureFlagOptions).toHaveBeenCalledWith({
            scope: 'all',
            page: '4',
          });
        });

        it('should make an API request when using tabs', () => {
          jest.spyOn(wrapper.vm, 'updateFeatureFlagOptions');
          wrapper.find(NavigationTabs).vm.$emit('onChangeTab', 'enabled');

          expect(wrapper.vm.updateFeatureFlagOptions).toHaveBeenCalledWith({
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

      factory();

      setImmediate(() => {
        done();
      });
    });

    it('should render error state', () => {
      const emptyState = wrapper.find(GlEmptyState);
      expect(emptyState.props('title')).toEqual('There was an error fetching the feature flags.');
      expect(emptyState.props('description')).toEqual(
        'Try again in a few moments or contact your support team.',
      );
    });

    it('renders configure button', () => {
      expect(configureButton().exists()).toBe(true);
    });

    it('renders new feature flag button', () => {
      expect(newButton().exists()).toBe(true);
    });
  });

  describe('rotate instance id', () => {
    beforeEach(done => {
      mock
        .onGet(`${TEST_HOST}/endpoint.json`, { params: { scope: 'all', page: '1' } })
        .reply(200, getRequestData, {});
      factory();

      setImmediate(() => {
        done();
      });
    });

    it('should fire the rotate action when a `token` event is received', () => {
      const actionSpy = jest.spyOn(wrapper.vm, 'rotateInstanceId');
      const modal = wrapper.find(ConfigureFeatureFlagsModal);
      modal.vm.$emit('token');

      expect(actionSpy).toHaveBeenCalled();
    });
  });
});
