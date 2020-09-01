import { mount } from '@vue/test-utils';
import { getByText } from '@testing-library/dom';
import { useFakeDate } from 'helpers/fake_date';
import * as timeago from 'timeago.js';
import CreatedAt from '~/vue_shared/components/members/created_at.vue';

describe('CreatedAt', () => {
  // March 15th, 2020
  useFakeDate(2020, 2, 15);

  const date = '2020-03-01T00:00:00.000';
  const formattedDate = '2 weeks ago';

  timeago.format = jest.fn(() => formattedDate);

  const defaultProps = {
    date,
    createdBy: {
      name: 'Administrator',
      webUrl: 'https://gitlab.com/root',
    },
  };

  let wrapper;

  const createComponent = propsData => {
    wrapper = mount(CreatedAt, {
      propsData: {
        ...defaultProps,
        propsData,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('displays value value returned by `timeago.js`', () => {
    createComponent();

    expect(timeago.format).toHaveBeenCalledWith(date);
    expect(getByText(wrapper.element, formattedDate)).not.toBe(null);
  });

  describe('when `createdBy` prop is provided', () => {
    it('displays a link to the user that created the member', () => {
      createComponent();

      const link = getByText(wrapper.element, 'Administrator');

      expect(link).not.toBe(null);
      expect(link.getAttribute('href')).toBe('https://gitlab.com/root');
    });
  });
});
