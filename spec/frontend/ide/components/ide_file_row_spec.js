import { createLocalVue, mount } from '@vue/test-utils';
import Vuex from 'vuex';
import IdeFileRow from '~/ide/components/ide_file_row.vue';
import FileRow from '~/vue_shared/components/file_row.vue';
import FileRowExtra from '~/ide/components/file_row_extra.vue';
import { createStore } from '~/ide/stores';

const localVue = createLocalVue();
localVue.use(Vuex);

const defaultComponentProps = (type = 'tree') => ({
  level: 4,
  file: {
    type,
    name: 'js',
  },
});

describe('Ide File Row component', () => {
  let wrapper;

  const createComponent = (props = {}) => {
    wrapper = mount(IdeFileRow, {
      propsData: { ...props },
      store: createStore(),
      localVue,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders file row component', () => {
    createComponent(defaultComponentProps());
    expect(wrapper.find(FileRow).exists()).toEqual(true);
  });

  it('hides dropdown when mouseleave', () => {
    createComponent(defaultComponentProps());
    wrapper.setMethods({
      toggleDropdown: jest.fn(),
    });

    wrapper.trigger('mouseleave');

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.vm.toggleDropdown).toHaveBeenCalled();
      expect(wrapper.vm.toggleDropdown).toHaveBeenCalledWith(false);
    });
  });

  describe('FileRowExtra component', () => {
    it('hides dropdown on click', () => {
      createComponent(defaultComponentProps());
      wrapper.setMethods({
        toggleDropdown: jest.fn(),
      });

      wrapper.find(FileRowExtra).vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.toggleDropdown).toHaveBeenCalled();
        expect(wrapper.vm.toggleDropdown).toHaveBeenCalledWith(false);
      });
    });

    it('call dropdown on toggle', () => {
      createComponent(defaultComponentProps());
      wrapper.setMethods({
        toggleDropdown: jest.fn(),
      });
      wrapper.find(FileRowExtra).vm.$emit('toggle');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.vm.toggleDropdown).toHaveBeenCalled();
      });
    });

    it.each`
      type       | value    | desc
      ${'tree'}  | ${true}  | ${'is shown if file type is tree'}
      ${'hello'} | ${false} | ${'is hidden if file is not tree'}
    `('$desc', ({ type, value }) => {
      createComponent(defaultComponentProps(type));
      expect(wrapper.find(FileRowExtra).exists()).toEqual(value);
    });
  });
});
