import { shallowMount } from '@vue/test-utils';
import UploadButton from 'ee/design_management/components/upload/button.vue';

describe('Design management upload button component', () => {
  let vm;

  function createComponent(isSaving = false, isInverted = false) {
    vm = shallowMount(UploadButton, {
      propsData: {
        isSaving,
        isInverted,
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

  it('renders inverted upload design button', () => {
    createComponent(false, true);

    expect(vm.element).toMatchSnapshot();
  });

  it('renders loading icon', () => {
    createComponent(true);

    expect(vm.element).toMatchSnapshot();
  });

  describe('onFileUploadChange', () => {
    it('emits upload event', () => {
      createComponent();

      jest.spyOn(vm.find({ ref: 'fileUpload' }).element, 'files', 'get').mockReturnValue('test');

      vm.vm.onFileUploadChange('test');

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
