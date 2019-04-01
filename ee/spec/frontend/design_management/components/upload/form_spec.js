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

  it('renders upload design button', () => {
    createComponent();

    expect(vm.element).toMatchSnapshot();
  });

  it('renders loading icon', () => {
    createComponent(true);

    expect(vm.element).toMatchSnapshot();
  });

  it('hides button if cant upload', () => {
    createComponent(false, false);

    expect(vm.element).toMatchSnapshot();
  });

  describe('onFileUploadChange', () => {
    it('emits upload event', () => {
      createComponent();

      jest.spyOn(vm.find({ ref: 'fileUpload' }).element, 'files', 'get').mockReturnValue('test');

      vm.vm.onFileUploadChange();

      expect(vm.emitted().upload[0]).toEqual(['test']);
    });
  });

  describe('openFileUpload', () => {
    it('triggers click on input', () => {
      createComponent();

      const clickSpy = jest.spyOn(vm.find({ ref: 'fileUpload' }).element, 'click');

      vm.vm.openFileUpload();

      expect(clickSpy).toHaveBeenCalled();
    });
  });
});
