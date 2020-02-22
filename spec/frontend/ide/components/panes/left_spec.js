import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import LeftPane from '~/ide/components/panes/left.vue';
import IdeSideBar from '~/ide/components/ide_side_bar.vue';
import IdeProjectHeader from '~/ide/components/ide_project_header.vue';
import { leftSidebarViews } from '~/ide/constants';

const TEST_NAMESPACE = 'test_namespace';
const TEST_PROJECT_ID = `${TEST_NAMESPACE}/test_project`;
const TEST_PROJECT_WEB_URL = 'http://example.com/test-web-url';
const TEST_PROJECT = {
  web_url: TEST_PROJECT_WEB_URL,
};

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ide/components/panes/left.vue', () => {
  let wrapper;
  let store;

  function createComponent(props, stubs = {}) {
    wrapper = shallowMount(LeftPane, {
      localVue,
      store,
      propsData: {
        ...props,
      },
      stubs,
    });
  }

  beforeEach(() => {
    store = createStore();
    store.replaceState({
      ...store.state,
      projects: {
        [TEST_PROJECT_ID]: TEST_PROJECT,
      },
      currentProjectId: TEST_PROJECT_ID,
    });
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  it('allows tabs to be added via extensionTabs prop', () => {
    createComponent({
      extensionTabs: [
        {
          show: true,
          title: 'FakeTab',
        },
      ],
    });

    expect(wrapper.find(IdeSideBar).props('tabs')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          show: true,
          title: 'FakeTab',
        }),
      ]),
    );
  });

  it('shows edit tab', () => {
    createComponent();

    expect(wrapper.find(IdeSideBar).props('tabs')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          show: true,
          title: 'Edit',
          views: expect.arrayContaining([
            expect.objectContaining({
              name: leftSidebarViews.edit.name,
            }),
          ]),
          buttonClasses: ['js-ide-edit-mode'],
        }),
      ]),
    );
  });

  it('shows review tab', () => {
    createComponent();

    expect(wrapper.find(IdeSideBar).props('tabs')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          show: true,
          title: 'Review',
          views: expect.arrayContaining([
            expect.objectContaining({
              name: leftSidebarViews.review.name,
            }),
          ]),
          buttonClasses: ['js-ide-review-mode'],
        }),
      ]),
    );
  });

  it('shows commit tab if there are changes', () => {
    store.replaceState({
      ...store.state,
      changedFiles: ['changed_file.txt'],
    });
    createComponent();

    expect(wrapper.find(IdeSideBar).props('tabs')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          show: true,
          title: 'Commit',
          views: expect.arrayContaining([
            expect.objectContaining({
              name: leftSidebarViews.commit.name,
            }),
          ]),
          buttonClasses: ['js-ide-commit-mode', 'qa-commit-mode-tab'],
        }),
      ]),
    );
  });

  it('does not show commit tab if there are not changes', () => {
    createComponent();

    expect(wrapper.find(IdeSideBar).props('tabs')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          show: false,
          title: 'Commit',
        }),
      ]),
    );
  });

  it('switches to ide tab if if there are no longer changes', done => {
    createComponent();

    store.replaceState({
      ...store.state,
      changedFiles: ['changed_file.txt'],
    });

    store.dispatch('updateActivityBarView', leftSidebarViews.commit.name);

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(store.state.currentActivityView).toEqual(leftSidebarViews.commit.name);
        expect(wrapper.find(IdeSideBar).props('tabs')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              show: true,
              title: 'Commit',
            }),
          ]),
        );
      })
      .then(() => {
        store.replaceState({
          ...store.state,
          changedFiles: [],
        });
      })
      .then(() => {
        expect(wrapper.find(IdeSideBar).props('tabs')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              show: false,
              title: 'Commit',
            }),
          ]),
        );
        expect(store.state.currentActivityView).toEqual(leftSidebarViews.edit.name);
      })
      .then(done)
      .catch(done.fail);
  });

  it('shows edit tab by default', () => {
    createComponent();
    expect(store.state.currentActivityView).toBe(leftSidebarViews.edit.name);
    expect(store.state.viewer).toBe('editor');
  });

  it('footer contains commit-form', () => {
    createComponent();

    const ideSideBarWrapper = wrapper.find(IdeSideBar);
    // NOTE: this is the only way I could find to test the existence and props of this component
    // without using Jest snapshot testing.  This component can't be tested like the others
    // in this spec because it is nested **within another component** inside the child component.
    //
    // If it were a slot directly inside the child component, then you could simply use
    // `wrapper.find(CommitForm)`
    //
    // Also note that this problem only occurs with the new `v-slot` (or shorthand `#`) syntax.
    // The deprecated `slot` syntax still works by simply using `wrapper.find(CommitForm)`
    // UPDATE: This is because Vue Test Utils doesn't support this, and it will
    // hopefully be fixed soon via this issue: https://github.com/vuejs/vue-test-utils/issues/1261
    const commitFormVNode = ideSideBarWrapper.vm.$slots.footer;

    expect(commitFormVNode).not.toBeUndefined();
  });

  describe('when not loading', () => {
    describe('project header', () => {
      it('is shown', () => {
        createComponent({}, { IdeSideBar });
        const ideProjectHeaderWrapper = wrapper.find(IdeProjectHeader);
        expect(ideProjectHeaderWrapper.props('project').web_url).toEqual(TEST_PROJECT_WEB_URL);
      });
    });
  });

  describe('when loading', () => {
    describe('project header', () => {
      describe('project header', () => {
        it('is shown', () => {
          createComponent({}, { IdeSideBar });
          const ideProjectHeaderWrapper = wrapper.find(IdeProjectHeader);
          expect(ideProjectHeaderWrapper.props('project').web_url).toEqual(TEST_PROJECT_WEB_URL);
        });
      });
    });
  });
});
