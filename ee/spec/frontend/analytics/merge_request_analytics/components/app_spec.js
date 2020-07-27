import { shallowMount } from '@vue/test-utils';
import MergeRequestAnalyticsApp from 'ee/analytics/merge_request_analytics/components/app.vue';

describe('MergeRequestAnalyticsApp', () => {
  let wrapper;

  const createComponent = () => {
    wrapper = shallowMount(MergeRequestAnalyticsApp);
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays the page title', () => {
    const pageTitle = wrapper.find('[data-testid="pageTitle"').text();

    expect(pageTitle).toEqual('Merge Request Analytics');
  });
});
