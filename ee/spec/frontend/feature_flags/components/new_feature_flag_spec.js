import Vuex from 'vuex';
import Vue from 'vue';
import { createLocalVue, mount } from '@vue/test-utils';
import Form from 'ee/feature_flags/components/form.vue';
import newModule from 'ee/feature_flags/store/modules/new';
import NewFeatureFlag from 'ee/feature_flags/components/new_feature_flag.vue';
import { ROLLOUT_STRATEGY_ALL_USERS, DEFAULT_PERCENT_ROLLOUT } from 'ee/feature_flags/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('New feature flag form', () => {
  let wrapper;

  const store = new Vuex.Store({
    modules: {
      new: newModule,
    },
  });

  const factory = () => {
    wrapper = mount(localVue.extend(NewFeatureFlag), {
      localVue,
      propsData: {
        endpoint: 'feature_flags.json',
        path: '/feature_flags',
        environmentsEndpoint: 'environments.json',
      },
      store,
      sync: false,
    });
  };

  beforeEach(() => {
    factory();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('with error', () => {
    it('should render the error', done => {
      store.dispatch('new/receiveCreateFeatureFlagError', { message: ['The name is required'] });
      Vue.nextTick(() => {
        expect(wrapper.find('.alert').exists()).toEqual(true);
        expect(wrapper.find('.alert').text()).toContain('The name is required');
        done();
      });
    });
  });

  it('renders form title', () => {
    expect(wrapper.find('h3').text()).toEqual('New feature flag');
  });

  it('should render feature flag form', () => {
    expect(wrapper.find(Form).exists()).toEqual(true);
  });

  it('should render default * row', () => {
    expect(wrapper.vm.scopes).toEqual([
      {
        id: expect.any(String),
        environmentScope: '*',
        active: true,
        rolloutStrategy: ROLLOUT_STRATEGY_ALL_USERS,
        rolloutPercentage: DEFAULT_PERCENT_ROLLOUT,
        rolloutUserIds: [],
      },
    ]);

    expect(wrapper.find('.js-scope-all').exists()).toEqual(true);
  });
});
