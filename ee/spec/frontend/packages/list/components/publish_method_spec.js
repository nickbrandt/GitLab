import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import PublishMethod from 'ee/packages/list/components/publish_method.vue';
import { packageList } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('publish_method', () => {
  let wrapper;
  let store;

  const [packageWithoutPipeline, packageWithPipeline] = packageList;

  const findPipelineRef = () => wrapper.find({ ref: 'pipeline-ref' });
  const findPipelineSha = () => wrapper.find({ ref: 'pipeline-sha' });
  const findManualPublish = () => wrapper.find({ ref: 'manual-ref' });

  const mountComponent = packageEntity => {
    store = new Vuex.Store({
      getters: {
        getCommitLink: () => () => {
          return 'commit-link';
        },
      },
    });

    wrapper = shallowMount(PublishMethod, {
      localVue,
      store,
      propsData: {
        packageEntity,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('renders', () => {
    mountComponent(packageWithPipeline);
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('pipeline information', () => {
    it('displays branch and commit when pipeline info exists', () => {
      mountComponent(packageWithPipeline);

      expect(findPipelineRef().exists()).toBe(true);
      expect(findPipelineSha().exists()).toBe(true);
    });

    it('does not show any pipeline details when no information exists', () => {
      mountComponent(packageWithoutPipeline);

      expect(findPipelineRef().exists()).toBe(false);
      expect(findPipelineSha().exists()).toBe(false);
      expect(findManualPublish().exists()).toBe(true);
      expect(findManualPublish().text()).toBe('Manually Published');
    });
  });
});
