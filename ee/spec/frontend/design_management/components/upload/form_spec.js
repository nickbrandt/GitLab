import { shallowMount } from '@vue/test-utils';
import UploadForm from 'ee/design_management/components/upload/form.vue';

describe('Design management upload form component', () => {
  let wrapper;

  function createComponent(isSaving = false, canUploadDesign = true) {
    wrapper = shallowMount(UploadForm, {
      sync: false,
      propsData: {
        isSaving,
        canUploadDesign,
        projectPath: '',
        issueIid: '',
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('renders upload design button', () => {
    createComponent();

    expect(wrapper.element).toMatchSnapshot();
  });

  it('hides button if cant upload', () => {
    createComponent(false, false);

    expect(wrapper.element).toMatchSnapshot();
  });

  describe('onFileUploadChange', () => {
    it('emits upload event', () => {
      createComponent();

      wrapper.vm.onFileUploadChange('test');

      expect(wrapper.emitted().upload[0]).toEqual(['test']);
    });
  });
});
