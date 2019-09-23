import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import MockAdapter from 'axios-mock-adapter';
import Form from 'ee/feature_flags/components/form.vue';
import editModule from 'ee/feature_flags/store/modules/edit';
import EditFeatureFlag from 'ee/feature_flags/components/edit_feature_flag.vue';
import { TEST_HOST } from 'spec/test_constants';
import axios from '~/lib/utils/axios_utils';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Edit feature flag form', () => {
  let wrapper;
  let mock;

  const store = new Vuex.Store({
    modules: {
      edit: editModule,
    },
  });

  const factory = () => {
    wrapper = shallowMount(localVue.extend(EditFeatureFlag), {
      localVue,
      propsData: {
        endpoint: `${TEST_HOST}/feature_flags.json'`,
        path: '/feature_flags',
        environmentsEndpoint: 'environments.json',
      },
      provide: {
        glFeatures: {
          featureFlagIID: true,
        },
      },
      store,
      sync: false,
    });
  };

  beforeEach(done => {
    mock = new MockAdapter(axios);

    mock.onGet(`${TEST_HOST}/feature_flags.json'`).replyOnce(200, {
      id: 21,
      iid: 5,
      active: false,
      created_at: '2019-01-17T17:27:39.778Z',
      updated_at: '2019-01-17T17:27:39.778Z',
      name: 'feature_flag',
      description: '',
      edit_path: '/h5bp/html5-boilerplate/-/feature_flags/21/edit',
      destroy_path: '/h5bp/html5-boilerplate/-/feature_flags/21',
      scopes: [
        {
          id: 21,
          active: false,
          environment_scope: '*',
          created_at: '2019-01-17T17:27:39.778Z',
          updated_at: '2019-01-17T17:27:39.778Z',
        },
      ],
    });

    factory();

    setImmediate(() => done());
  });

  afterEach(() => {
    wrapper.destroy();
    mock.restore();
  });

  it('should display the iid', () => {
    expect(wrapper.find('h3').text()).toContain('^5');
  });

  describe('with error', () => {
    it('should render the error', done => {
      store.dispatch('edit/receiveUpdateFeatureFlagError', { message: ['The name is required'] });

      wrapper.vm.$nextTick(() => {
        expect(wrapper.find('.alert-danger').exists()).toEqual(true);
        expect(wrapper.find('.alert-danger').text()).toContain('The name is required');
        done();
      });
    });
  });

  describe('without error', () => {
    it('renders form title', () => {
      expect(wrapper.text()).toContain('^5 feature_flag');
    });

    it('should render feature flag form', () => {
      expect(wrapper.find(Form).exists()).toEqual(true);
    });
  });
});
