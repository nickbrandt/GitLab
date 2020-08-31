import { mount } from '@vue/test-utils';
import { getByText, getByTestId } from '@testing-library/dom';
import MembersList from '~/vue_shared/components/members/members_list.vue';
import * as initUserPopovers from '~/user_popovers';
import { member, members } from './mock_data';

describe('MemberList', () => {
  let wrapper;

  const defaultProps = {
    members,
  };

  const createComponent = props => {
    wrapper = mount(MembersList, {
      propsData: {
        ...defaultProps,
        ...props,
      },
      stubs: ['member-info', 'created-at', 'time-ago-tooltip', 'expires-at'],
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('fields', () => {
    describe('when `optionalFields` prop is passed', () => {
      it.each`
        field          | label
        ${'source'}    | ${'Source'}
        ${'granted'}   | ${'Access Granted'}
        ${'invited'}   | ${'Invited'}
        ${'requested'} | ${'Requested'}
      `('renders the $label field', ({ field, label }) => {
        createComponent({
          optionalFields: [field],
        });

        expect(getByText(wrapper.element, label, { selector: '[role="columnheader"]' })).not.toBe(
          null,
        );
      });
    });

    describe('non-optional fields', () => {
      it.each`
        label
        ${'Account'}
        ${'Access Expires'}
        ${'Max Role'}
        ${'Expiration'}
      `('renders the $label field', ({ label }) => {
        createComponent();

        expect(getByText(wrapper.element, label, { selector: '[role="columnheader"]' })).not.toBe(
          null,
        );
      });
    });

    it('renders "Actions" field for screen readers', () => {
      createComponent();

      const actionField = getByTestId(wrapper.element, 'col-actions');

      expect(actionField).not.toBe(null);
      expect(actionField).toHaveClass('gl-sr-only');
    });

    describe('Source field', () => {
      describe('when `member.source` is `null`', () => {
        it('displays "Direct member"', () => {
          createComponent({
            members: [
              {
                ...member,
                source: null,
              },
            ],
            optionalFields: ['source'],
          });

          expect(getByText(wrapper.element, 'Direct member')).not.toBe(null);
        });
      });

      describe('when `member.source.id` is different than `sourceId` prop', () => {
        it('displays link to the group the member was inherited from', () => {
          createComponent({
            sourceId: 123,
            optionalFields: ['source'],
          });

          const link = getByText(wrapper.element, 'Foo Bar');

          expect(link).not.toBe(null);
          expect(link.getAttribute('href')).toBe('https://gitlab.com/groups/foo-bar');
        });
      });
    });
  });

  describe('when `members` prop is an empty array', () => {
    it('displays a "No members found" message', () => {
      createComponent({
        members: [],
      });

      expect(getByText(wrapper.element, 'No members found')).not.toBe(null);
    });
  });

  it('initializes user popovers when mounted', () => {
    const initUserPopoversMock = jest.spyOn(initUserPopovers, 'default');

    createComponent();

    expect(initUserPopoversMock).toHaveBeenCalled();
  });
});
