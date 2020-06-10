import { shallowMount } from '@vue/test-utils';
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import UrlSyncComponent from '~/vue_shared/components/url_sync.vue';
import setWindowLocation from 'helpers/set_window_location_helper';

jest.mock('~/lib/utils/url_utility', () => ({
  setUrlParams: jest.fn(val => `urlParams: ${val}`),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  historyPushState: jest.fn(),
}));

describe('url sync component', () => {
  let wrapper;
  const mockQuery = { group_id: '5014437163714', project_ids: ['5014437608314'] };
  const TEST_HOST = 'http://testhost/';

  jest.mock();
  setWindowLocation(TEST_HOST);

  const createComponent = () => {
    wrapper = shallowMount(UrlSyncComponent, {
      propsData: { query: mockQuery },
    });
  };

  function expectUrlSync(query) {
    expect(setUrlParams).toHaveBeenCalledTimes(1);
    expect(setUrlParams).toHaveBeenCalledWith(query, TEST_HOST, true);

    const setUrlParamsReturnValue = setUrlParams.mock.results[0].value;
    expect(historyPushState).toHaveBeenCalledTimes(1);
    expect(historyPushState).toHaveBeenCalledWith(setUrlParamsReturnValue);
  }

  beforeEach(() => {
    createComponent();
  });

  it('immediately syncs the query to the URL', () => expectUrlSync(mockQuery));

  describe('when the query is modified', () => {
    const newQuery = { foo: true };
    beforeEach(() => {
      setUrlParams.mockClear();
      historyPushState.mockClear();
      wrapper.setProps({ query: newQuery });
    });

    it('updates the URL with the new query', () => expectUrlSync(newQuery));
  });
});
