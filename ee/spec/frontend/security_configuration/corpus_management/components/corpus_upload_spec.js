import { GlButton } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import Target from 'ee/security_configuration/corpus_management/components/corpus_upload.vue';

describe('Corpus Upload', () => {
  let wrapper;

  const createComponentFactory = (mountFn = shallowMount) => (options = {}) => {
    const defaultProps = { totalSize: 4e8 };
    wrapper = mountFn(Target, {
      propsData: defaultProps,
      ...options,
    });
  };

  const createComponent = createComponentFactory();

  afterEach(() => {
    wrapper.destroy();
  });

  describe('component', () => {
    it('renders header', () => {
      createComponent();
      expect(wrapper.findComponent(GlButton).exists()).toBe(true);
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
