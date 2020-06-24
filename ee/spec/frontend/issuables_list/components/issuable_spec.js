import { mount } from '@vue/test-utils';
import Issuable from '~/issuables_list/components/issuable.vue';
import IssueSubepicFlag from 'ee_component/issue/issue_subpepic_flag.vue';
import { TEST_HOST } from 'helpers/test_constants';
import { getParameterValues } from '~/lib/utils/url_utility';
import { simpleIssue } from '../../../../../spec/frontend/issuables_list/issuable_list_test_data';

jest.mock('~/lib/utils/url_utility', () => ({
  getParameterValues: jest.fn().mockReturnValue([]),
}));

const TEST_BASE_URL = `${TEST_HOST}/issues`;
const TEST_EPIC_FILTER_ID = '36';

describe('Issuable component', () => {
  let wrapper;

  const factory = (props = {}) => {
    wrapper = mount(Issuable, {
      propsData: {
        issuable: simpleIssue,
        baseUrl: TEST_BASE_URL,
        ...props,
      },
      stubs: {
        'issue-subepic-flag': IssueSubepicFlag,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findSubepicFlag = () => wrapper.find(IssueSubepicFlag);

  describe('subepic flag on mounted', () => {
    it('does not render if epic filter does not have a value', () => {
      getParameterValues.mockImplementation(() => []);
      factory();

      expect(findSubepicFlag().exists()).toBe(false);
    });

    it('renders if epic filter has a value', async () => {
      getParameterValues.mockImplementation(() => [TEST_EPIC_FILTER_ID]);
      factory();

      return wrapper.vm.$nextTick().then(() => {
        expect(findSubepicFlag().exists()).toBe(true);
      });
    });
  });
});
