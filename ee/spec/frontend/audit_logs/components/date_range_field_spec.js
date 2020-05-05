import { shallowMount } from '@vue/test-utils';
import { GlDaterangePicker } from '@gitlab/ui';

import DateRangeField from 'ee/audit_logs/components/date_range_field.vue';
import { parsePikadayDate } from '~/lib/utils/datetime_utility';

describe('DateRangeField component', () => {
  const DATE = '1970-01-01';
  let wrapper;

  const createComponent = (props = {}) => {
    const formElement = document.createElement('form');
    document.body.appendChild(formElement);

    return shallowMount(DateRangeField, {
      propsData: { formElement, ...props },
    });
  };

  beforeEach(() => {
    delete window.location;
    window.location = { search: '' };
  });

  afterEach(() => {
    document.querySelector('form').remove();
    wrapper.destroy();
  });

  it('should populate the initial start date if passed in the query string', () => {
    window.location.search = `?created_after=${DATE}`;
    wrapper = createComponent();

    expect(wrapper.find(GlDaterangePicker).props()).toMatchObject({
      defaultStartDate: parsePikadayDate(DATE),
      defaultEndDate: null,
    });
  });

  it('should populate the initial end date if passed in the query string', () => {
    window.location.search = `?created_before=${DATE}`;
    wrapper = createComponent();

    expect(wrapper.find(GlDaterangePicker).props()).toMatchObject({
      defaultStartDate: null,
      defaultEndDate: parsePikadayDate(DATE),
    });
  });

  it('should populate both the initial start and end dates if passed in the query string', () => {
    window.location.search = `?created_after=${DATE}&created_before=${DATE}`;
    wrapper = createComponent();

    expect(wrapper.find(GlDaterangePicker).props()).toMatchObject({
      defaultStartDate: parsePikadayDate(DATE),
      defaultEndDate: parsePikadayDate(DATE),
    });
  });

  it('should populate the date hidden fields on input', () => {
    wrapper = createComponent();

    wrapper
      .find(GlDaterangePicker)
      .vm.$emit('input', { startDate: parsePikadayDate(DATE), endDate: parsePikadayDate(DATE) });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.find('input[name="created_after"]').attributes().value).toEqual(DATE);
      expect(wrapper.find('input[name="created_before"]').attributes().value).toEqual(DATE);
    });
  });

  it('should submit the form on input change', () => {
    wrapper = createComponent();
    const spy = jest.spyOn(wrapper.props().formElement, 'submit');

    wrapper
      .find(GlDaterangePicker)
      .vm.$emit('input', { startDate: parsePikadayDate(DATE), endDate: parsePikadayDate(DATE) });

    return wrapper.vm.$nextTick().then(() => {
      expect(spy).toHaveBeenCalledTimes(1);
    });
  });
});
