import { createLocalVue, shallowMount } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import IdeSideBar from '~/ide/components/ide_side_bar.vue';
import Vuex from 'vuex';

const localVue = createLocalVue();
localVue.use(Vuex);

// NOTE: This is just a temporary quick clone of the CollapsibleSidebar spec to get some test
// coverage.  IdeSideBar will soon be refactored away and replaced with CollapsibleSidebar
describe('ide/components/ide_side_bar.vue', () => {
  let wrapper;
  let store;

  const fakeComponentName = 'fake-component';

  const createComponent = props => {
    wrapper = shallowMount(IdeSideBar, {
      localVue,
      store,
      propsData: {
        tabs: [],
        ...props,
      },
      slots: {
        footer: '<div class="footer-slot"/>',
      },
    });
  };

  const findTabButton = () => wrapper.find(`[data-qa-selector="${fakeComponentName}_tab_button"]`);

  beforeEach(() => {
    store = createStore();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('with a tab', () => {
    let fakeView;
    let tabs;
    let button;

    beforeEach(() => {
      const FakeComponent = localVue.component(fakeComponentName, {
        render: () => {},
      });

      fakeView = {
        name: fakeComponentName,
        keepAlive: true,
        component: FakeComponent,
      };

      tabs = [
        {
          show: true,
          title: fakeComponentName,
          views: [fakeView],
          icon: 'text-description',
          buttonClasses: ['button-class-1', 'button-class-2'],
        },
      ];

      createComponent({ tabs });
      button = findTabButton();
    });

    it('correctly renders left side attributes', () => {
      button.trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.find('.js-tab-view').exists()).toBeTruthy();
        expect(wrapper.find('.js-tab-view').classes()).toContain('d-flex');
      });
    });

    it('correctly renders tab-specific classes', () => {
      store.state.currentActivityView = fakeComponentName;

      return wrapper.vm.$nextTick().then(() => {
        expect(button.classes()).toContain('button-class-1');
        expect(button.classes()).toContain('button-class-2');
      });
    });

    it('can show a tab with an active view', () => {
      store.state.currentActivityView = fakeComponentName;

      return wrapper.vm.$nextTick().then(() => {
        expect(button.classes()).toEqual(expect.arrayContaining(['ide-sidebar-link', 'active']));
        expect(button.attributes('data-original-title')).toEqual(fakeComponentName);
        expect(wrapper.find('.js-tab-view').exists()).toBe(true);
      });
    });

    it('shows footer', () => {
      expect(wrapper.find('.footer-slot').exists()).toBeTruthy();
    });
  });
});
