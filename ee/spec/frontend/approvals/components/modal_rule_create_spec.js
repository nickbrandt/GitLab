import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { createStoreOptions } from 'ee/approvals/stores';
import projectSettingsModule from 'ee/approvals/stores/modules/project_settings';
import RuleForm from 'ee/approvals/components/rule_form.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('RuleForm', () => {
  const exampleRule = {
    id: 1,
    name: 'Example',
    approvalsRequired: 0,
    users: [],
    groups: [],
  };
  let wrapper;
  let store;

  const findNameInput = () => wrapper.find('input[name=name]');
  const createStore = () => createStoreOptions(projectSettingsModule(), { projectId: '7' });
  const createComponent = (vuexStore, props = {}) =>
    shallowMount(localVue.extend(RuleForm), {
      propsData: {
        ...props,
      },
      store: new Vuex.Store(vuexStore),
      localVue,
      sync: false,
    });

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    if (wrapper) wrapper.destroy();
  });

  describe('isNameDisabled', () => {
    beforeEach(() => {
      store.state.settings.allowMultiRule = true;
    });

    describe('When creating the License-Check rule', () => {
      beforeEach(() => {
        wrapper = createComponent(store, {
          initRule: { ...exampleRule, ...{ id: null, name: 'License-Check' } },
        });
      });

      it('does not disable the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe(undefined);
      });
    });

    describe('When creating any other rule', () => {
      beforeEach(() => {
        wrapper = createComponent(store, {
          initRule: { ...exampleRule, ...{ id: null, name: 'QA' } },
        });
      });

      it('does not disable the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe(undefined);
      });
    });

    describe('When editing the License-Check rule', () => {
      beforeEach(() => {
        wrapper = createComponent(store, {
          initRule: { ...exampleRule, ...{ id: 1, name: 'License-Check' } },
        });
      });

      it('disables the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe('disabled');
      });
    });

    describe('When editing any other rule', () => {
      beforeEach(() => {
        wrapper = createComponent(store, {
          initRule: { ...exampleRule, ...{ id: 1, name: 'QA' } },
        });
      });

      it('does not disable the name text field', () => {
        expect(findNameInput().attributes('disabled')).toBe(undefined);
      });
    });
  });
});
