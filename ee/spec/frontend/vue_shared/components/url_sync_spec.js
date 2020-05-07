import { shallowMount } from '@vue/test-utils';
import { historyPushState } from '~/lib/utils/common_utils';
import { setUrlParams } from '~/lib/utils/url_utility';
import UrlSyncComponent from '~/vue_shared/components/url_sync.vue';

jest.mock('~/lib/utils/url_utility', () => ({
  setUrlParams: jest.fn(val => `urlParams: ${val}`),
}));

jest.mock('~/lib/utils/common_utils', () => ({
  historyPushState: jest.fn(),
}));

describe('url sync component', () => {
  let wrapper;
  const query = { group_id: '5014437163714', project_ids: ['5014437608314'] };

  jest.mock();

  const createComponent = () => {
    wrapper = shallowMount(UrlSyncComponent, {
      propsData: { query },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  describe('when the query is modified', () => {
    beforeEach(() => {
      // "Don't test the framework"
      // https://vuedose.tips/tips/testing-logic-inside-a-vue-js-watcher/
      wrapper.vm.$options.watch.query.handler.call(wrapper.vm);
    });

    it('should call setUrlParams', () => {
      expect(setUrlParams).toHaveBeenCalledTimes(1);
      // we use `expect.anything()` in argument 2 to prevent flaky tests with `window.location`
      expect(setUrlParams).toHaveBeenCalledWith(query, expect.anything(), true);
    });

    it('should call historyPushState', () => {
      expect(historyPushState).toHaveBeenCalledTimes(1);
      expect(historyPushState).toHaveBeenCalledWith(setUrlParams(query));
    });
  });
});
