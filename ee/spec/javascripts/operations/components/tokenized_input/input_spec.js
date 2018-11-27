import Vue from 'vue';
import store from 'ee/operations/store/index';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import TokenizedInput from 'ee/operations/components/tokenized_input/input.vue';
import { clearState } from '../../helpers';
import { mockProjectData } from '../../mock_data';

describe('tokenized input component', () => {
  const TokenizedInputComponent = Vue.extend(TokenizedInput);
  const mockProjects = mockProjectData(1);
  const [mockOneProject] = mockProjects;
  const mockInputValue = 'mock-inputValue';

  let vm;
  const getInput = () => vm.$refs.input;

  beforeEach(() => {
    store.state.projectTokens = mockProjects;
    vm = mountComponentWithStore(TokenizedInputComponent, { store });
  });

  afterEach(() => {
    vm.$destroy();
    clearState(store);
  });

  it('focuses input on click', () => {
    const spy = spyOn(getInput(), 'focus');
    vm.$el.click();

    expect(spy).toHaveBeenCalled();
  });

  it('renders input token', () => {
    expect(vm.$el.querySelector('.js-input-token').innerText.trim()).toBe(
      mockOneProject.name_with_namespace,
    );
  });

  it('removes input tokens on click', () => {
    const spy = spyOn(vm.$store, 'dispatch');
    vm.$el.querySelector('.js-token-remove').click();

    expect(spy).toHaveBeenCalledWith('removeProjectTokenAt', mockOneProject.id);
  });

  describe('input', () => {
    it('updates input value when local value changes', done => {
      vm.localInputValue = mockInputValue;

      vm.$nextTick(() => {
        expect(getInput().value).toBe(mockInputValue);
        done();
      });
    });

    it('handles focus', () => {
      const spy = spyOn(vm, '$emit');
      vm.onFocus();

      expect(spy).toHaveBeenCalledWith('focus');
    });

    it('handles blur', () => {
      const spy = spyOn(vm, '$emit');
      vm.onBlur();

      expect(spy).toHaveBeenCalledWith('blur');
    });
  });

  describe('wrapped components', () => {
    describe('icon', () => {
      it('should render close for input tokens', () => {
        expect(vm.$el.querySelectorAll('.ic-close').length).toBe(mockProjects.length);
      });

      it('should render search', () => {
        expect(vm.$el.querySelector('.ic-search')).not.toBe(null);
      });
    });
  });
});
