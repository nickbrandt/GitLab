import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlFormInput } from '@gitlab/ui';
import component from 'ee/feature_flags/components/strategies/user_with_id.vue';

const localVue = createLocalVue();

describe('User With ID', () => {
  const Component = localVue.extend(component);
  let wrapper;
  let propsData;

  afterEach(() => wrapper.destroy());

  beforeEach(() => {
    propsData = {
      value: [],
    };

    wrapper = shallowMount(Component, {
      propsData,
      localVue,
    });
  });

  describe('input change', () => {
    it('should split a value by comma', () => {
      wrapper.vm.updateUserIds('123,456,789');

      expect(wrapper.emitted('input')).toContainEqual([['123', '456', '789']]);
    });
    it('should clear the value of the userId', () => {
      wrapper.vm.userId = '123';
      wrapper.vm.updateUserIds('123');

      expect(wrapper.vm.userId).toBe('');
    });
    it('should add new ids to the array of user ids', () => {
      wrapper.setProps({ value: ['123', '456', '789'] });
      wrapper.vm.updateUserIds('321,654,987');

      expect(wrapper.emitted('input')).toContainEqual([['123', '456', '789', '321', '654', '987']]);
    });
    it('should dedupe newly added IDs', () => {
      wrapper.vm.updateUserIds('123,123,123');

      expect(wrapper.emitted('input')).toContainEqual([['123']]);
    });
    it('should only allow the addition of new IDs', () => {
      wrapper.vm.updateUserIds('123,123,123');
      expect(wrapper.emitted('input')).toContainEqual([['123']]);

      wrapper.vm.updateUserIds('123,123,123,456');
      expect(wrapper.emitted('input')).toContainEqual([['123', '456']]);
    });
    it('should only allow the addition of truthy values', () => {
      wrapper.vm.updateUserIds(',,,,,,');

      expect(wrapper.vm.value).toEqual([]);
    });
    it('should be called on the input change event', () => {
      wrapper.setMethods({ updateUserIds: jest.fn() });
      wrapper.find(GlFormInput).trigger('keyup', { keyCode: 13 });

      expect(wrapper.vm.updateUserIds).toHaveBeenCalled();
    });
  });

  describe('remove', () => {
    it('should remove the given ID', () => {
      wrapper.setProps({ value: ['0', '1', '2', '3'] });
      wrapper.vm.removeUser('1');

      expect(wrapper.emitted('input')[0]).toEqual([['0', '2', '3']]);
    });
    it('should not do anything if the ID is not present', () => {
      wrapper.setProps({ value: ['0', '1', '2', '3'] });
      wrapper.vm.removeUser('-1');
      wrapper.vm.removeUser('6');

      expect(wrapper.emitted('input')[0]).toEqual([['0', '1', '2', '3']]);
      expect(wrapper.emitted('input')[1]).toEqual([['0', '1', '2', '3']]);
    });
    it('should be bound to the remove button on a badge', () => {
      wrapper.setProps({ value: ['0', '1', '2', '3'] });
      wrapper.setMethods({ removeUser: jest.fn() });

      wrapper.find('span').trigger('click');
      expect(wrapper.vm.removeUser).toHaveBeenCalled();
    });
  });

  describe('clearAll', () => {
    it('should reset the user ids to an empty array', () => {
      wrapper.setProps({ value: ['0', '1', '2', '3'] });
      wrapper.vm.clearAll();

      expect(wrapper.emitted('input')).toContainEqual([[]]);
    });

    it('should be bound to the clear all button', () => {
      wrapper.setMethods({ clearAll: jest.fn() });
      wrapper.find('[variant="danger"]').vm.$emit('click');

      expect(wrapper.vm.clearAll).toHaveBeenCalled();
    });
  });
});
