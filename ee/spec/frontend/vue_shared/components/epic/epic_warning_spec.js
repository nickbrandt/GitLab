import { shallowMount } from '@vue/test-utils';
import EpicWarning from 'ee/vue_shared/components/epic/epic_warning.vue';
import { store } from '~/notes/stores';
import { GlIcon } from '@gitlab/ui';

describe('Epic Warning Component', () => {
  let wrapper;

  const findIcon = () => wrapper.find(GlIcon);
  const findConfidentialBlock = () => wrapper.find({ ref: 'confidential' });
  const findEpicWarning = () => wrapper.find({ ref: 'epicWarning' });

  const createComponent = (props, isNoteableEpic = true) => {
    wrapper = shallowMount(EpicWarning, {
      store,
      propsData: {
        ...props,
      },
      computed: {
        isNoteableTypeEpic() {
          return isNoteableEpic;
        },
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('when noteable type is epic', () => {
    describe('epic is not confidential', () => {
      beforeEach(() => {
        createComponent({ isConfidential: false });
      });

      it('does not render warning icon', () => {
        expect(findIcon().exists()).toBe(false);
      });

      it('does not render information about epic issue', () => {
        expect(findConfidentialBlock().exists()).toBe(false);
      });
    });

    describe('epic is confidential', () => {
      beforeEach(() => {
        createComponent({ isConfidential: true });
      });

      it('renders information about confidential epic', () => {
        expect(findConfidentialBlock().exists()).toBe(true);
        expect(findConfidentialBlock().element).toMatchSnapshot();
      });

      it('renders warning icon', () => {
        expect(findIcon().exists()).toBe(true);
      });
    });
  });

  describe('when noteable type is not epic', () => {
    beforeEach(() => {
      createComponent({ isConfidential: true }, false);
    });

    it('does not render itself', () => {
      expect(findEpicWarning().exists()).toBe(false);
    });
  });
});
