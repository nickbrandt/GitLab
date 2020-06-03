import { shallowMount } from '@vue/test-utils';
import { GlNewDropdownItem } from '@gitlab/ui';

import * as urlUtils from '~/lib/utils/url_utility';

import SortingField from 'ee/audit_events/components/sorting_field.vue';

describe('SortingField component', () => {
  let wrapper;

  const DUMMY_URL = 'https://localhost';
  const createComponent = () =>
    shallowMount(SortingField, { stubs: { GlNewDropdown: true, GlNewDropdownItem: true } });

  const getCheckedOptions = () =>
    wrapper.findAll(GlNewDropdownItem).filter(item => item.props().isChecked);

  const getCheckedOptionHref = () => {
    return getCheckedOptions()
      .at(0)
      .attributes().href;
  };

  beforeEach(() => {
    urlUtils.setUrlParams = jest.fn(({ sort }) => `${DUMMY_URL}/?sort=${sort}`);
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Sorting behaviour', () => {
    it('should have sorting options', () => {
      expect(wrapper.findAll(GlNewDropdownItem)).toHaveLength(2);
    });

    it('should set the sorting option to `created_desc` by default', () => {
      expect(getCheckedOptions()).toHaveLength(1);
      expect(getCheckedOptionHref()).toBe(`${DUMMY_URL}/?sort=created_desc`);
    });

    it('should get the sorting option from the URL', () => {
      urlUtils.queryToObject = jest.fn(() => ({ sort: 'created_asc' }));
      wrapper = createComponent();

      expect(getCheckedOptions()).toHaveLength(1);
      expect(getCheckedOptionHref()).toBe(`${DUMMY_URL}/?sort=created_asc`);
    });

    it('should retain other params when creating the option URL', () => {
      urlUtils.setUrlParams = jest.fn(({ sort }) => `${DUMMY_URL}/?abc=defg&sort=${sort}`);
      urlUtils.queryToObject = jest.fn(() => ({ sort: 'created_desc', abc: 'defg' }));

      wrapper = createComponent();

      expect(getCheckedOptionHref()).toBe(`${DUMMY_URL}/?abc=defg&sort=created_desc`);
    });
  });
});
