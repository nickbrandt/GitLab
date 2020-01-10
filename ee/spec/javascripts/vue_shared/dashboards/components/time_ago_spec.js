import { shallowMount, createLocalVue } from '@vue/test-utils';
import TimeAgo from 'ee/vue_shared/dashboards/components/time_ago.vue';

const localVue = createLocalVue();

describe('time ago component', () => {
  const TimeAgoComponent = localVue.extend(TimeAgo);
  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(TimeAgoComponent, {
      localVue,
      propsData: {
        time: new Date(Date.now() - 86400000).toISOString(),
        tooltipText: 'Finished',
      },
    });
  });

  describe('render', () => {
    it('renders clock icon', () => {
      expect(wrapper.contains('.js-dashboard-project-clock-icon')).toBe(true);
    });

    it('renders time ago of finished time', () => {
      const timeago = '1 day ago';
      const container = wrapper.element.querySelector('.js-dashboard-project-time-ago');

      expect(container.innerText.trim()).toBe(timeago);
    });
  });
});
