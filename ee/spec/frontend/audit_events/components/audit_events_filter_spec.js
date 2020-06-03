import { GlFilteredSearch } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';

import AuditEventsFilter from 'ee/audit_events/components/audit_events_filter.vue';
import { AVAILABLE_TOKEN_TYPES } from 'ee/audit_events/constants';

describe('AuditEventsFilter', () => {
  let wrapper;
  const formElement = document.createElement('form');
  formElement.submit = jest.fn();

  const findFilteredSearch = () => wrapper.find(GlFilteredSearch);
  const getAvailableTokens = () => findFilteredSearch().props('availableTokens');
  const getAvailableTokenProps = type =>
    getAvailableTokens().filter(token => token.type === type)[0];

  const initComponent = (props = {}) => {
    wrapper = shallowMount(AuditEventsFilter, {
      propsData: {
        ...props,
      },
      methods: {
        getFormElement: () => formElement,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe.each`
    type         | title
    ${'Project'} | ${'Project Events'}
    ${'Group'}   | ${'Group Events'}
    ${'User'}    | ${'User Events'}
  `('for the list of available tokens', ({ type, title }) => {
    it(`creates a unique token for ${type}`, () => {
      initComponent();
      expect(getAvailableTokenProps(type)).toMatchObject({
        title,
        unique: true,
        operators: [expect.objectContaining({ value: '=' })],
      });
    });
  });

  describe('when the URL query has a search term', () => {
    const type = 'User';
    const id = '1';

    beforeEach(() => {
      delete window.location;
      window.location = { search: `entity_type=${type}&entity_id=${id}` };
      initComponent();
    });

    it('sets the filtered searched token', () => {
      expect(findFilteredSearch().props('value')).toMatchObject([
        {
          type,
          value: {
            data: id,
          },
        },
      ]);
    });
  });

  describe('when the URL query is empty', () => {
    beforeEach(() => {
      delete window.location;
      window.location = { search: '' };
      initComponent();
    });

    it('has an empty search value', () => {
      expect(findFilteredSearch().vm.value).toEqual([]);
    });
  });

  describe('when submitting the filtered search', () => {
    beforeEach(() => {
      initComponent();
      findFilteredSearch().vm.$emit('submit');
    });

    it("calls submit on this component's FORM element", () => {
      expect(formElement.submit).toHaveBeenCalledWith();
    });
  });

  describe('when a search token has been selected', () => {
    const searchTerm = {
      value: { data: '1' },
      type: 'Project',
    };
    beforeEach(() => {
      initComponent();
      wrapper.setData({
        searchTerms: [searchTerm],
      });
    });

    it('only one token matching the selected type is available', () => {
      expect(getAvailableTokenProps('Project').disabled).toEqual(false);
      expect(getAvailableTokenProps('Group').disabled).toEqual(true);
      expect(getAvailableTokenProps('User').disabled).toEqual(true);
    });

    it('sets the input values according to the search term', () => {
      expect(wrapper.find('input[name="entity_type"]').attributes().value).toEqual(searchTerm.type);
      expect(wrapper.find('input[name="entity_id"]').attributes().value).toEqual(
        searchTerm.value.data,
      );
    });
  });

  describe('when enabling just a single token type', () => {
    const type = AVAILABLE_TOKEN_TYPES[0];

    beforeEach(() => {
      initComponent({
        enabledTokenTypes: [type],
      });
    });

    it('only the enabled token type is available for selection', () => {
      expect(getAvailableTokens().length).toEqual(1);
      expect(getAvailableTokens()).toMatchObject([{ type }]);
    });
  });

  describe('when setting the QA selector', () => {
    beforeEach(() => {
      initComponent();
    });

    it('should not set the QA selector if not provided', () => {
      wrapper.vm.$nextTick(() => {
        expect(
          wrapper.find('[data-testid="audit-events-filter"]').attributes('data-qa-selector'),
        ).toBeUndefined();
      });
    });

    it('should set the QA selector if provided', () => {
      wrapper.setProps({ qaSelector: 'qa_selector' });
      wrapper.vm.$nextTick(() => {
        expect(
          wrapper.find('[data-testid="audit-events-filter"]').attributes('data-qa-selector'),
        ).toEqual('qa_selector');
      });
    });
  });
});
