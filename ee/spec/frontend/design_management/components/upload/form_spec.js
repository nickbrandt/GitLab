import { shallowMount } from '@vue/test-utils';
import UploadForm from 'ee/design_management/components/upload/form.vue';

describe('Design management upload form component', () => {
  let vm;

  function createComponent(isSaving = false, canUploadDesign = true) {
    vm = shallowMount(UploadForm, {
      propsData: {
        isSaving,
        canUploadDesign,
      },
    });
  }

  afterEach(() => {
    vm.destroy();
  });

  it('renders upload design button', () => {
    createComponent();

    expect(vm.element).toMatchSnapshot();
  });

  it('hides button if cant upload', () => {
    createComponent(false, false);

    expect(vm.element).toMatchSnapshot();
  });

  describe('onFileUploadChange', () => {
    it('emits upload event', () => {
      createComponent();

      vm.vm.onFileUploadChange('test');

      expect(vm.emitted().upload[0]).toEqual(['test']);
    });
  });
});
