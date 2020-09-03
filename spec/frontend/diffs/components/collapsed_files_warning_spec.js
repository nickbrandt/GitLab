import Vuex from 'vuex';
import { shallowMount, mount, createLocalVue } from '@vue/test-utils';
import createStore from '~/diffs/store/modules';
import CollapsedFilesWarning from '~/diffs/components/collapsed_files_warning.vue';
import { CENTERED_LIMITED_CONTAINER_CLASSES } from '~/diffs/constants';

const propsData = {
  limited: true,
  mergeable: true,
  resolutionPath: 'a-path',
};
const limitedClasses = CENTERED_LIMITED_CONTAINER_CLASSES.split(' ');

function getAlertActionButton(wrapper) {
  return wrapper.find('.gl-alert-actions button.gl-alert-action:first-child').element;
}

function getAlertCloseButton(wrapper) {
  return wrapper.find('[data-testid="close-icon"]').element.parentNode;
}

describe('CollapsedFilesWarning', () => {
  const localVue = createLocalVue();
  let store;
  let wrapper;

  localVue.use(Vuex);

  const createComponent = (props = {}, { full } = { full: false }) => {
    const mounter = full ? mount : shallowMount;
    store = new Vuex.Store({
      modules: {
        diffs: createStore(),
      },
    });

    wrapper = mounter(CollapsedFilesWarning, {
      propsData: { ...propsData, ...props },
      localVue,
      store,
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  it.each`
    limited  | containerClasses
    ${true}  | ${limitedClasses}
    ${false} | ${[]}
  `(
    'has the correct container classes when limited is $limited',
    ({ limited, containerClasses }) => {
      createComponent({ limited });

      expect(wrapper.classes()).toEqual(containerClasses);
    },
  );

  it.each`
    present  | dismissed
    ${false} | ${true}
    ${true}  | ${false}
  `('toggles the alert when dismissed is $dismissed', ({ present, dismissed }) => {
    createComponent({ dismissed });

    expect(wrapper.find('[data-testid="root"]').exists()).toBe(present);
  });

  it('dismisses the component when the alert "x" is clicked', () => {
    createComponent({}, { full: true });

    expect(wrapper.vm.isDismissed).toBe(false);

    getAlertCloseButton(wrapper).click();

    expect(wrapper.vm.isDismissed).toBe(true);
  });

  it('triggers the expandAllFiles action when the alert action button is clicked', () => {
    createComponent({}, { full: true });

    jest.spyOn(wrapper.vm.$store, 'dispatch').mockReturnValue(undefined);

    getAlertActionButton(wrapper).click();

    expect(wrapper.vm.$store.dispatch).toHaveBeenCalledWith('diffs/expandAllFiles', undefined);
  });
});
