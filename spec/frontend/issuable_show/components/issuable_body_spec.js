import { shallowMount } from '@vue/test-utils';
import { useFakeDate } from 'helpers/fake_date';

import IssuableBody from '~/issuable_show/components/issuable_body.vue';

import IssuableTitle from '~/issuable_show/components/issuable_title.vue';
import IssuableDescription from '~/issuable_show/components/issuable_description.vue';
import IssuableEditForm from '~/issuable_show/components/issuable_edit_form.vue';
import TimeAgoTooltip from '~/vue_shared/components/time_ago_tooltip.vue';

import { mockIssuableShowProps, mockIssuable } from '../mock_data';

jest.mock('~/autosave');

const issuableBodyProps = {
  ...mockIssuableShowProps,
  issuable: mockIssuable,
};

const createComponent = (propsData = issuableBodyProps) =>
  shallowMount(IssuableBody, {
    propsData,
    stubs: {
      IssuableTitle,
      IssuableDescription,
      IssuableEditForm,
      TimeAgoTooltip,
    },
    slots: {
      'status-badge': 'Open',
      'edit-form-actions': `
        <button class="js-save">Save changes</button>
        <button class="js-cancel">Cancel</button>
      `,
    },
  });

describe('IssuableBody', () => {
  // Some assertions expect a date later than our default
  useFakeDate(2020, 11, 11);

  let wrapper;

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('computed', () => {
    describe('isUpdated', () => {
      it.each`
        updatedAt                 | returnValue
        ${mockIssuable.updatedAt} | ${true}
        ${null}                   | ${false}
        ${''}                     | ${false}
      `(
        'returns $returnValue when value of `updateAt` prop is `$updatedAt`',
        async ({ updatedAt, returnValue }) => {
          wrapper.setProps({
            issuable: {
              ...mockIssuable,
              updatedAt,
            },
          });

          await wrapper.vm.$nextTick();

          expect(wrapper.vm.isUpdated).toBe(returnValue);
        },
      );
    });

    describe('updatedBy', () => {
      it('returns value of `issuable.updatedBy`', () => {
        expect(wrapper.vm.updatedBy).toBe(mockIssuable.updatedBy);
      });
    });
  });

  describe('template', () => {
    it('renders issuable-title component', () => {
      const titleEl = wrapper.find(IssuableTitle);

      expect(titleEl.exists()).toBe(true);
      expect(titleEl.props()).toMatchObject({
        issuable: issuableBodyProps.issuable,
        statusBadgeClass: issuableBodyProps.statusBadgeClass,
        statusIcon: issuableBodyProps.statusIcon,
        enableEdit: issuableBodyProps.enableEdit,
      });
    });

    it('renders issuable-description component', () => {
      const descriptionEl = wrapper.find(IssuableDescription);

      expect(descriptionEl.exists()).toBe(true);
      expect(descriptionEl.props('issuable')).toEqual(issuableBodyProps.issuable);
    });

    it('renders issuable edit info', () => {
      const editedEl = wrapper.find('small');

      expect(editedEl.text()).toMatchInterpolatedText('Edited 9 months ago by Administrator');
    });

    it('renders issuable-edit-form when `editFormVisible` prop is true', async () => {
      wrapper.setProps({
        editFormVisible: true,
      });

      await wrapper.vm.$nextTick();

      const editFormEl = wrapper.find(IssuableEditForm);
      expect(editFormEl.exists()).toBe(true);
      expect(editFormEl.props()).toMatchObject({
        issuable: issuableBodyProps.issuable,
        enableAutocomplete: issuableBodyProps.enableAutocomplete,
        descriptionPreviewPath: issuableBodyProps.descriptionPreviewPath,
        descriptionHelpPath: issuableBodyProps.descriptionHelpPath,
      });
      expect(editFormEl.find('button.js-save').exists()).toBe(true);
      expect(editFormEl.find('button.js-cancel').exists()).toBe(true);
    });

    describe('events', () => {
      it('component emits `edit-issuable` event bubbled via issuable-title', () => {
        const issuableTitle = wrapper.find(IssuableTitle);

        issuableTitle.vm.$emit('edit-issuable');

        expect(wrapper.emitted('edit-issuable')).toBeTruthy();
      });

      it.each(['keydown-title', 'keydown-description'])(
        'component emits `%s` event with event object and issuableMeta params via issuable-edit-form',
        async (eventName) => {
          const eventObj = {
            preventDefault: jest.fn(),
            stopPropagation: jest.fn(),
          };
          const issuableMeta = {
            issuableTitle: 'foo',
            issuableDescription: 'foobar',
          };

          wrapper.setProps({
            editFormVisible: true,
          });

          await wrapper.vm.$nextTick();

          const issuableEditForm = wrapper.find(IssuableEditForm);

          issuableEditForm.vm.$emit(eventName, eventObj, issuableMeta);

          expect(wrapper.emitted(eventName)).toBeTruthy();
          expect(wrapper.emitted(eventName)[0]).toMatchObject([eventObj, issuableMeta]);
        },
      );
    });
  });
});
