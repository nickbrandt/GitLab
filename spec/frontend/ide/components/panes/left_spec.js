import Vuex from 'vuex';
import { createLocalVue, shallowMount } from '@vue/test-utils';
import { createStore } from '~/ide/stores';
import LeftPane from '~/ide/components/panes/left.vue';
import CollapsibleSidebar from '~/ide/components/panes/collapsible_sidebar.vue';
import ProjectAvatarDefault from '~/vue_shared/components/project_avatar/default.vue';
import { leftSidebarViews } from '~/ide/constants';
import RepoCommitSection from '../../../../../app/assets/javascripts/ide/components/repo_commit_section';

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

    expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
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

    expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
      expect.arrayContaining([
        expect.objectContaining({
          show: true,
          title: 'Edit',
          views: expect.arrayContaining([
            expect.objectContaining({
              name: leftSidebarViews.ideTree.name,
            }),
          ]),
          buttonClasses: ['js-ide-edit-mode'],
        }),
      ]),
    );
  });

  it('shows review tab', () => {
    createComponent();

    expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
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

    expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
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

    expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
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

    store.dispatch('leftPane/open', { component: RepoCommitSection, ...leftSidebarViews.commit });

    wrapper.vm
      .$nextTick()
      .then(() => {
        expect(store.state.leftPane.currentView).toEqual(leftSidebarViews.commit.name);
        expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
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
        expect(wrapper.find(CollapsibleSidebar).props('extensionTabs')).toEqual(
          expect.arrayContaining([
            expect.objectContaining({
              show: false,
              title: 'Commit',
            }),
          ]),
        );
        expect(store.state.leftPane.currentView).toEqual(leftSidebarViews.ideTree.name);
      })
      .then(done)
      .catch(done.fail);
  });

  it('opens edit tab by default', () => {
    createComponent();
    expect(store.state.leftPane.isOpen).toBeTruthy();
    expect(store.state.leftPane.currentView).toBe(leftSidebarViews.ideTree.name);
    expect(store.state.viewer).toBe('editor');
  });

  it('footer contains commit-form', () => {
    createComponent();

    const collapsibleSidebarWrapper = wrapper.find(CollapsibleSidebar);
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
    const commitFormVNode = collapsibleSidebarWrapper.vm.$slots.footer;

    expect(commitFormVNode).not.toBeUndefined();
  });

  describe('when not loading', () => {
    describe('project avatar header icon', () => {
      it('is shown', () => {
        createComponent({}, { CollapsibleSidebar });
        expect(wrapper.find('[data-qa-selector="ide-header-icon"]').attributes('href')).toEqual(
          TEST_PROJECT_WEB_URL,
        );
      });
    });

    describe('project header title', () => {
      it('is shown', () => {
        createComponent();

        const collapsibleSidebarWrapper = wrapper.find(CollapsibleSidebar);
        // NOTE: this is the only way I could find to test the existence and props of this component
        // without using Jest snapshot testing.  This component can't be tested like the others
        // in this spec because it is nested **within another component** inside the child component.
        //
        // If it were a slot directly inside the child component, then you could simply use
        // `wrapper.find(IdeProjectHeader)`
        //
        // Also note that this problem only occurs with the new `v-slot` (or shorthand `#`) syntax.
        // The deprecated `slot` syntax still works by simply using `wrapper.find(IdeProjectHeader)`.
        // UPDATE: This is because Vue Test Utils doesn't support this, and it will
        // hopefully be fixed soon via this issue: https://github.com/vuejs/vue-test-utils/issues/1261
        const ideProjectHeaderVNode = collapsibleSidebarWrapper.vm.$slots.header[0];

        expect(ideProjectHeaderVNode).not.toBeNull();
        expect(ideProjectHeaderVNode.componentOptions.propsData.project).toEqual(TEST_PROJECT);
      });
    });
  });

  describe('when loading', () => {
    describe('project avatar header icon', () => {
      it('is not shown', () => {
        store.replaceState({
          ...store.state,
          loading: true,
        });

        createComponent({}, { CollapsibleSidebar });

        expect(wrapper.find('.ide-header-icon').exists()).toBeFalsy();
        expect(wrapper.find(ProjectAvatarDefault).exists()).toBeFalsy();
      });
    });

    describe('project header title', () => {
      it('is not shown', () => {
        store.replaceState({
          ...store.state,
          loading: true,
        });

        createComponent();

        const collapsibleSidebarWrapper = wrapper.find(CollapsibleSidebar);
        const ideProjectHeader = collapsibleSidebarWrapper.vm.$slots.header;

        expect(ideProjectHeader).toBeUndefined();
      });
    });
  });
});
