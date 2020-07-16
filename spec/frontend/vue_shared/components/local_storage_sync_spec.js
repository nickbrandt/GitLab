import { shallowMount } from '@vue/test-utils';
import LocalStorageSync from '~/vue_shared/components/local_storage_sync.vue';

describe('Local Storage Sync', () => {
  let wrapper;

  const createComponent = ({ props = {}, slots = {} } = {}) => {
    wrapper = shallowMount(LocalStorageSync, {
      propsData: props,
      slots,
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    localStorage.clear();
  });

  it('is a renderless component', () => {
    const html = '<div class="test-slot"></div>';
    createComponent({
      props: {
        storageKey: 'key',
      },
      slots: {
        default: html,
      },
    });

    expect(wrapper.html()).toBe(html);
  });

  describe('localStorage empty', () => {
    const storageKey = 'issue_list_order';

    it('does not emit input event', () => {
      createComponent({
        props: {
          storageKey,
          value: 'ascending',
        },
      });

      expect(wrapper.emitted('input')).toBeFalsy();
    });

    it('does not save default value', () => {
      const value = 'ascending';

      createComponent({
        props: {
          storageKey,
          value,
        },
      });

      expect(localStorage.getItem(storageKey)).toBe(null);
    });
  });

  describe('localStorage has saved value', () => {
    const storageKey = 'issue_list_order_by';
    const savedValue = 'last_updated';

    beforeEach(() => {
      localStorage.setItem(storageKey, savedValue);
    });

    it('emits input event with saved value', () => {
      createComponent({
        props: {
          storageKey,
          value: 'ascending',
        },
      });

      expect(wrapper.emitted('input')[0][0]).toBe(savedValue);
    });

    it('does not overwrite localStorage with prop value', () => {
      createComponent({
        props: {
          storageKey,
          value: 'created',
        },
      });

      expect(localStorage.getItem(storageKey)).toBe(savedValue);
    });

    it('updating the value updates localStorage', async () => {
      createComponent({
        props: {
          storageKey,
          value: 'created',
        },
      });

      const newValue = 'last_updated';
      wrapper.setProps({
        value: newValue,
      });

      await wrapper.vm.$nextTick();

      expect(localStorage.getItem(storageKey)).toBe(newValue);
    });
  });

  describe.each([true, false])('localStorage has saved value', hasSavedValue => {
    const storageKey = 'issue_list_order_by';

    it.each`
      newValue                 | shouldBeParsed
      ${'newValue'}            | ${false}
      ${true}                  | ${true}
      ${false}                 | ${true}
      ${{ foo: 'bar ' }}       | ${true}
      ${['newValue', 1, true]} | ${true}
    `('stores $newValue to localStorage', async ({ newValue, shouldBeParsed }) => {
      if (hasSavedValue) {
        localStorage.setItem(storageKey, newValue);
      }

      createComponent({
        props: {
          storageKey,
          value: 'oldValue',
        },
      });

      wrapper.setProps({
        value: newValue,
      });

      await wrapper.vm.$nextTick();

      const rawStorageItem = localStorage.getItem(storageKey);
      const valueToCheck = shouldBeParsed ? JSON.parse(rawStorageItem) : rawStorageItem;

      expect(valueToCheck).toEqual(newValue);
    });
  });
});
