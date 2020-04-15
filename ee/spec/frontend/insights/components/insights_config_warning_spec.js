import InsightsConfigWarning from 'ee/insights/components/insights_config_warning.vue';
import { shallowMount } from '@vue/test-utils';

describe('Insights config warning component', () => {
  const image = 'illustrations/monitoring/getting_started.svg';
  const title = 'There are no charts configured for this page';
  const summary =
    'Please check the configuration file to ensure that a collection of charts has been declared.';

  let wrapper;

  beforeEach(() => {
    wrapper = shallowMount(InsightsConfigWarning, {
      propsData: { image, title, summary },
    });
  });

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders the component', () => {
    expect(
      wrapper
        .findAll('.content-image')
        .at(0)
        .attributes('src'),
    ).toContain(image);

    expect(wrapper.find('.content-title').text()).toBe(title);
    expect(wrapper.find('.content-summary').text()).toBe(summary);
  });
});
