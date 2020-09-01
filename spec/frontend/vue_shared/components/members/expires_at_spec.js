import { mount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import { useFakeDate } from 'helpers/fake_date';
import ExpiresAt from '~/vue_shared/components/members/expires_at.vue';

describe('ExpiresAt', () => {
  // March 15th, 2020
  useFakeDate(2020, 2, 15);

  let wrapper;

  const createComponent = propsData => {
    wrapper = mount(ExpiresAt, {
      propsData,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when no expiration date is set', () => {
    it('displays "No expiration set"', () => {
      createComponent({ date: null });

      expect(getByText(wrapper.element, 'No expiration set')).not.toBe(null);
    });
  });

  describe('when expiration date is in the past', () => {
    it('displays "Expired"', () => {
      createComponent({ date: '2019-03-15T00:00:00.000' });

      const expiredText = getByText(wrapper.element, 'Expired');

      expect(expiredText).not.toBe(null);
      expect(expiredText.closest('.gl-text-red-500')).not.toBe(null);
    });
  });

  describe('when expiration date is in the future', () => {
    it.each`
      date                         | expected                   | warningColor
      ${'2020-03-23T00:00:00.000'} | ${'in 8 days'}             | ${false}
      ${'2020-03-20T00:00:00.000'} | ${'in 5 days'}             | ${true}
      ${'2020-03-16T00:00:00.000'} | ${'in 1 day'}              | ${true}
      ${'2020-03-15T05:00:00.000'} | ${'in about 5 hours'}      | ${true}
      ${'2020-03-15T01:00:00.000'} | ${'in about 1 hour'}       | ${true}
      ${'2020-03-15T00:30:00.000'} | ${'in 30 minutes'}         | ${true}
      ${'2020-03-15T00:01:15.000'} | ${'in 1 minute'}           | ${true}
      ${'2020-03-15T00:00:15.000'} | ${'in less than a minute'} | ${true}
    `('displays "$expected"', ({ date, expected, warningColor }) => {
      createComponent({ date });

      const expiredText = getByText(wrapper.element, expected);

      expect(expiredText).not.toBe(null);

      if (warningColor) {
        expect(expiredText).toHaveClass('gl-text-orange-500');
      } else {
        expect(expiredText).not.toHaveClass('gl-text-orange-500');
      }
    });
  });
});
