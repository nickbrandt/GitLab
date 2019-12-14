import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlEmptyState, GlLoadingIcon } from '@gitlab/ui';
import InstanceSecurityDashboard from 'ee/security_dashboard/components/instance_security_dashboard.vue';
import SecurityDashboard from 'ee/security_dashboard/components/app.vue';
import ProjectManager from 'ee/security_dashboard/components/project_manager.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

const dashboardDocumentation = '/help/docs';
const emptyStateSvgPath = '/svgs/empty.svg';
const emptyDashboardStateSvgPath = '/svgs/empty-dash.svg';
const projectAddEndpoint = '/projects/add';
const projectListEndpoint = '/projects/list';
const vulnerabilitiesEndpoint = '/vulnerabilities';
const vulnerabilitiesCountEndpoint = '/vulnerabilities_summary';
const vulnerabilitiesHistoryEndpoint = '/vulnerabilities_history';
const vulnerabilityFeedbackHelpPath = '/vulnerabilities_feedback_help';

describe('Instance Security Dashboard component', () => {
  let store;
  let wrapper;
  let actionResolvers;

  const factory = ({ projects = [] } = {}) => {
    store = new Vuex.Store({
      modules: {
        projectSelector: {
          namespaced: true,
          actions: {
            fetchProjects() {},
            setProjectEndpoints() {},
          },
          state: {
            projects,
          },
        },
      },
    });

    actionResolvers = [];
    jest.spyOn(store, 'dispatch').mockImplementation(
      () =>
        new Promise(resolve => {
          actionResolvers.push(resolve);
        }),
    );

    wrapper = shallowMount(InstanceSecurityDashboard, {
      localVue,
      store,
      sync: false,
      propsData: {
        dashboardDocumentation,
        emptyStateSvgPath,
        emptyDashboardStateSvgPath,
        projectAddEndpoint,
        projectListEndpoint,
        vulnerabilitiesEndpoint,
        vulnerabilitiesCountEndpoint,
        vulnerabilitiesHistoryEndpoint,
        vulnerabilityFeedbackHelpPath,
      },
    });
  };

  const resolveActions = () => {
    actionResolvers.forEach(resolve => resolve());
  };

  const findProjectSelectorToggleButton = () => wrapper.find('.js-project-selector-toggle');

  const clickProjectSelectorToggleButton = () => {
    findProjectSelectorToggleButton().vm.$emit('click');

    return wrapper.vm.$nextTick();
  };

  const expectComponentWithProps = (Component, props) => {
    const componentWrapper = wrapper.find(Component);
    expect(componentWrapper.exists()).toBe(true);
    expect(componentWrapper.props()).toEqual(expect.objectContaining(props));
  };

  const expectProjectSelectorState = () => {
    expect(findProjectSelectorToggleButton().exists()).toBe(true);
    expect(wrapper.find(GlEmptyState).exists()).toBe(false);
    expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
    expect(wrapper.find(SecurityDashboard).exists()).toBe(false);
    expect(wrapper.find(ProjectManager).exists()).toBe(true);
  };

  afterEach(() => {
    wrapper.destroy();
  });

  describe('on creation', () => {
    beforeEach(() => {
      factory();
    });

    it('dispatches the expected actions', () => {
      expect(store.dispatch.mock.calls).toEqual([
        [
          'projectSelector/setProjectEndpoints',
          {
            add: projectAddEndpoint,
            list: projectListEndpoint,
          },
        ],
        ['projectSelector/fetchProjects', undefined],
      ]);
    });

    it('displays the initial loading state', () => {
      expect(findProjectSelectorToggleButton().exists()).toBe(false);
      expect(wrapper.find(GlEmptyState).exists()).toBe(false);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(true);
      expect(wrapper.find(SecurityDashboard).exists()).toBe(false);
      expect(wrapper.find(ProjectManager).exists()).toBe(false);
    });
  });

  describe('given there are no projects', () => {
    beforeEach(() => {
      factory();
      resolveActions();
    });

    it('renders the empty state', () => {
      expect(findProjectSelectorToggleButton().exists()).toBe(true);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(SecurityDashboard).exists()).toBe(false);
      expect(wrapper.find(ProjectManager).exists()).toBe(false);

      expectComponentWithProps(GlEmptyState, {
        svgPath: emptyStateSvgPath,
      });
    });

    describe('after clicking the project selector toggle button', () => {
      beforeEach(clickProjectSelectorToggleButton);

      it('renders the project selector state', () => {
        expectProjectSelectorState();
      });
    });
  });

  describe('given there are projects', () => {
    beforeEach(() => {
      factory({ projects: [{ name: 'foo', id: 1 }] });
      resolveActions();
    });

    it('renders the security dashboard state', () => {
      expect(findProjectSelectorToggleButton().exists()).toBe(true);
      expect(wrapper.find(GlEmptyState).exists()).toBe(false);
      expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
      expect(wrapper.find(ProjectManager).exists()).toBe(false);

      expectComponentWithProps(SecurityDashboard, {
        vulnerabilitiesEndpoint,
        vulnerabilitiesCountEndpoint,
        vulnerabilitiesHistoryEndpoint,
        vulnerabilityFeedbackHelpPath,
      });
    });

    describe('after clicking the project selector toggle button', () => {
      beforeEach(clickProjectSelectorToggleButton);

      it('renders the project selector state', () => {
        expectProjectSelectorState();
      });
    });
  });
});
