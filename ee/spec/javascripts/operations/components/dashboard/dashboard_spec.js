import Vue from 'vue';
import store from 'ee/operations/store/index';
import Dashboard from 'ee/operations/components/dashboard/dashboard.vue';
import DashboardProject from 'ee/operations/components/dashboard/project.vue';
import { trimText } from 'spec/helpers/vue_component_helper';
import { getChildInstances, clearState } from '../../helpers';
import { mockProjectData, mockText } from '../../mock_data';

describe('dashboard component', () => {
  const DashboardComponent = Vue.extend(Dashboard);
  const DashboardProjectComponent = Vue.extend(DashboardProject);
  const mount = () =>
    new DashboardComponent({
      store,
      propsData: {
        addPath: 'mock-addPath',
        listPath: 'mock-listPath',
        emptyDashboardSvgPath: '/assets/illustrations/operations-dashboard_empty.svg',
        emptyDashboardHelpPath: '/help/user/operations_dashboard/index.html',
      },
      methods: {
        fetchProjects: () => {},
      },
    }).$mount();
  let vm;

  beforeEach(() => {
    vm = mount();
  });

  afterEach(() => {
    vm.$destroy();
    clearState(store);
  });

  it('renders dashboard title', () => {
    expect(vm.$el.querySelector('.js-dashboard-title').innerText.trim()).toBe(
      mockText.DASHBOARD_TITLE,
    );
  });

  describe('add projects button', () => {
    let button;

    beforeEach(() => {
      button = vm.$el.querySelector('.js-add-projects-button');
    });

    it('renders add projects text', () => {
      expect(button.innerText.trim()).toBe(mockText.ADD_PROJECTS);
    });

    it('opens the Add Projects modal', () => {
      button.click();

      expect(vm.$el.querySelector('.add-projects-modal')).toBeDefined();
    });
  });

  describe('wrapped components', () => {
    describe('dashboard project component', () => {
      const projectCount = 1;
      const projects = mockProjectData(projectCount);

      beforeEach(() => {
        store.state.projects = projects;
        vm = mount();
      });

      it('includes a dashboard project component for each project', () => {
        expect(getChildInstances(vm, DashboardProjectComponent).length).toBe(projectCount);
      });

      it('passes each project to the dashboard project component', () => {
        const [oneProject] = projects;
        const [projectComponent] = getChildInstances(vm, DashboardProjectComponent);

        expect(projectComponent.project).toEqual(oneProject);
      });
    });

    describe('empty state', () => {
      beforeEach(() => {
        store.state.projects = [];
        vm = mount();
      });

      it('renders empty state svg after requesting projects with no results', () => {
        const svgSrc = vm.$el.querySelector('.js-empty-state-svg').src;

        expect(svgSrc).toMatch(mockText.EMPTY_SVG_SOURCE);
      });

      it('renders title', () => {
        expect(vm.$el.querySelector('.js-title').innerText.trim()).toBe(mockText.EMPTY_TITLE);
      });

      it('renders sub-title', () => {
        expect(trimText(vm.$el.querySelector('.js-sub-title').innerText)).toBe(
          mockText.EMPTY_SUBTITLE,
        );
      });

      it('renders link to documentation', () => {
        const link = vm.$el.querySelector('.js-documentation-link');

        expect(link.innerText.trim()).toBe('More information');
      });

      it('links to documentation', () => {
        const link = vm.$el.querySelector('.js-documentation-link');

        expect(link.href).toMatch(vm.emptyDashboardHelpPath);
      });
    });
  });
});
