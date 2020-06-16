import { shallowMount } from '@vue/test-utils';
import EpicLane from 'ee/boards/components/epic_lane.vue';
import { GlIcon } from '@gitlab/ui';
import { mockEpic } from '../mock_data';

describe('EpicLane', () => {
  let wrapper;

  const defaultProps = { epic: mockEpic };

  const createComponent = (props = {}) => {
    wrapper = shallowMount(EpicLane, {
      propsData: {
        ...defaultProps,
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('template', () => {
    beforeEach(() => {
      createComponent();
    });

    it('icon aria label is Opened when epic is opened', () => {
      expect(wrapper.find(GlIcon).attributes('aria-label')).toEqual('Opened');
    });

    it('icon aria label is Closed when epic is closed', () => {
      createComponent({ epic: { ...mockEpic, state: 'closed' } });
      expect(wrapper.find(GlIcon).attributes('aria-label')).toEqual('Closed');
    });

    it('displays total count of issues in epic', () => {
      expect(wrapper.find('[data-testid="epic-lane-issue-count"]').text()).toContain(5);
    });

    it('displays 2 icons', () => {
      expect(wrapper.findAll(GlIcon).length).toEqual(2);
    });

    it('displays epic title', () => {
      expect(wrapper.text()).toContain(mockEpic.title);
    });
  });
});
