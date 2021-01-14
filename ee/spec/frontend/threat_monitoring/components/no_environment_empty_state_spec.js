import { shallowMount } from '@vue/test-utils';
import NoEnvironmentEmptyState from 'ee/threat_monitoring/components/no_environment_empty_state.vue';

const documentationPath = '/docs';
const emptyStateSvgPath = '/svgs';

describe('NoEnvironmentEmptyState component', () => {
  let wrapper;

  const factory = () => {
    wrapper = shallowMount(NoEnvironmentEmptyState, {
      provide: {
        documentationPath,
        emptyStateSvgPath,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      factory();
    });

    it('matches the snapshot', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });
});
