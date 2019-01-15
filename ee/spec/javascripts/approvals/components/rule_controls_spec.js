import { createLocalVue, shallowMount } from '@vue/test-utils';
import Vuex from 'vuex';
import { GlButton } from '@gitlab/ui';
import Icon from '~/vue_shared/components/icon.vue';
import { createStoreOptions } from 'ee/approvals/stores';
import RuleControls from 'ee/approvals/components/rule_controls.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const TEST_RULE = { id: 10 };

describe('EE Approvals RuleControls', () => {
  let wrapper;
  let store;

  const factory = () => {
    wrapper = shallowMount(localVue.extend(RuleControls), {
      propsData: {
        rule: TEST_RULE,
      },
      localVue,
      store: new Vuex.Store(store),
    });
  };

  const findButton = label =>
    wrapper
      .findAll(GlButton)
      .filter(x => x.find(Icon).attributes('aria-label') === label)
      .at(0);

  beforeEach(() => {
    store = createStoreOptions();
    store.modules.createModal.actions.open = jasmine.createSpy('createModal/open');
    store.modules.deleteModal.actions.open = jasmine.createSpy('deleteModal/open');
  });

  describe('edit button', () => {
    let button;

    beforeEach(() => {
      factory();
      button = findButton('Edit');
    });

    it('exists', () => {
      expect(button.exists()).toBe(true);
    });

    it('when click, opens create modal', () => {
      expect(store.modules.createModal.actions.open).not.toHaveBeenCalled();

      button.vm.$emit('click');

      expect(store.modules.createModal.actions.open).toHaveBeenCalledWith(
        jasmine.anything(),
        TEST_RULE,
        undefined,
      );
    });
  });

  describe('remove button', () => {
    let button;

    beforeEach(() => {
      factory();
      button = findButton('Remove');
    });

    it('exists', () => {
      expect(button.exists()).toBe(true);
    });

    it('when click, opens delete modal', () => {
      expect(store.modules.deleteModal.actions.open).not.toHaveBeenCalled();

      button.vm.$emit('click');

      expect(store.modules.deleteModal.actions.open).toHaveBeenCalledWith(
        jasmine.anything(),
        TEST_RULE,
        undefined,
      );
    });
  });
});
