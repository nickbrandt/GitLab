import Vue from 'vue';
import store from 'ee/operations/store/index';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import ProjectSearch from 'ee/operations/components/dashboard/project_search.vue';
import TokenizedInput from 'ee/operations/components/tokenized_input/input.vue';
import { mockText, mockProjectData } from '../../mock_data';
import { getChildInstances, mouseEvent, clearState } from '../../helpers';

describe('project search component', () => {
  const ProjectSearchComponent = Vue.extend(ProjectSearch);
  const TokenizedInputComponent = Vue.extend(TokenizedInput);

  const mockProjects = mockProjectData(1);
  const [mockOneProject] = mockProjects;
  const mockInputValue = 'mock-inputValue';
  const mount = () => mountComponentWithStore(ProjectSearchComponent, { store });
  let vm;

  beforeEach(() => {
    vm = mount();
  });

  afterEach(() => {
    vm.$destroy();
    clearState(store);
  });

  describe('dropdown menu', () => {
    it('renders dropdown menu when input gains focus', done => {
      vm.$store.dispatch('setInputValue', mockInputValue);
      vm.isInputFocused = true;

      vm.$nextTick(() => {
        expect(vm.$el.classList.contains('show')).toBe(true);
        expect(vm.$el.querySelector('.js-search-results')).not.toBeNull();
        done();
      });
    });

    it('does not render when input is not focused', () => {
      vm.$store.dispatch('setInputValue', mockInputValue);

      expect(vm.$el.classList.contains('show')).toBe(false);
    });

    it('does not render when input value is empty', () => {
      vm.isInputFocused = true;

      expect(vm.$el.classList.contains('show')).toBe(false);
    });

    it('renders search icon', () => {
      expect(vm.$el.querySelector('.ic-search')).not.toBe(null);
    });

    it('renders search description', () => {
      store.state.inputValue = mockInputValue;
      vm = mountComponentWithStore(ProjectSearchComponent, { store });

      expect(vm.$el.querySelector('.js-search-results').innerText.trim()).toBe(
        `"${mockInputValue}" ${mockText.SEARCH_DESCRIPTION_SUFFIX}`,
      );
    });

    it('renders no search results after searching input with no matches', done => {
      vm.hasSearchedInput = true;

      vm.$nextTick(() => {
        expect(
          vm.$el
            .querySelector('.js-search-results')
            .innerText.trim()
            .slice(-mockText.NO_SEARCH_RESULTS.length),
        ).toBe(mockText.NO_SEARCH_RESULTS);
        done();
      });
    });

    it('renders loading icon when searching', () => {
      store.state.searchCount = 1;
      vm = mount();

      expect(vm.$el).toContainElement('.loading-container');
    });

    it('renders search results', () => {
      store.state.projectSearchResults = mockProjects;
      vm = mount();

      expect(vm.$el.getElementsByClassName('js-search-result').length).toBe(mockProjects.length);
    });
  });

  it('searches projects when input value changes', done => {
    const spy = spyOn(vm, 'queryInputInProjects');
    vm.$store.dispatch('setInputValue', mockInputValue);

    vm.$nextTick(() => {
      expect(spy).toHaveBeenCalled();
      done();
    });
  });

  describe('project search item', () => {
    let item;

    beforeEach(() => {
      store.state.projectSearchResults = mockProjects;
      vm = mount();
      item = vm.$el.querySelector('.js-search-result');
    });

    it('renders project name with namespace', () => {
      expect(item.querySelector('.js-name-with-namespace').innerText.trim()).toBe(
        mockOneProject.name_with_namespace,
      );
    });

    it('calls action to add project token on mousedown', done => {
      const spy = spyOn(vm.$store, 'dispatch');

      mouseEvent(item, 'mousedown');

      vm.$nextTick(() => {
        expect(spy).toHaveBeenCalledWith('addProjectToken', mockOneProject);
        done();
      });
    });
  });

  describe('wrapped components', () => {
    describe('tokenized input', () => {
      const getInput = parent => getChildInstances(parent, TokenizedInputComponent)[0];

      it('renders', () => {
        expect(getChildInstances(vm, TokenizedInputComponent).length).toBe(1);
      });

      it('handles focus', () => {
        getInput(vm).$emit('focus');

        expect(vm.isInputFocused).toBe(true);
      });

      it('handles blur', () => {
        getInput(vm).$emit('blur');

        expect(vm.isInputFocused).toBe(false);
      });
    });

    describe('project avatar', () => {
      let avatars;

      beforeEach(() => {
        store.state.projectSearchResults = mockProjects;
        vm = mount();
        avatars = vm.$el.querySelectorAll('.project-avatar');
      });

      it('renders project avatar component', () => {
        expect(avatars.length).toBe(1);
      });

      it('binds project to project', () => {
        const [avatar] = avatars;
        const identicon = avatar.querySelector('.identicon');
        const [identiconLetter] = mockOneProject.name;

        expect(identicon.textContent.trim()).toEqual(identiconLetter.toUpperCase());
      });
    });
  });
});
