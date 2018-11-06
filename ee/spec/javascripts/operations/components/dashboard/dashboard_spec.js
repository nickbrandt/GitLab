import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import store from 'ee/operations/store/index';
import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import Dashboard from 'ee/operations/components/dashboard/dashboard.vue';
import ProjectSearch from 'ee/operations/components/dashboard/project_search.vue';
import DashboardProject from 'ee/operations/components/dashboard/project.vue';
import { getChildInstances, clearState } from '../../helpers';
import { mockProjectData, mockText } from '../../mock_data';

describe('dashboard component', () => {
  const DashboardComponent = Vue.extend(Dashboard);
  const ProjectSearchComponent = Vue.extend(ProjectSearch);
  const DashboardProjectComponent = Vue.extend(DashboardProject);
  const projectTokens = mockProjectData(1);
  const mockListPath = 'mock-listPath';
  const mount = () =>
    mountComponentWithStore(DashboardComponent, {
      store,
      props: {
        addPath: 'mock-addPath',
        listPath: mockListPath,
        emptyDashboardSvgPath: '/assets/illustrations/operations-dashboard_empty.svg',
      },
    });
  let vm;
  let mockAxios;

  beforeEach(() => {
    vm = mount();
    mockAxios = new MockAdapter(axios);
  });

  afterEach(() => {
    vm.$destroy();
    clearState(store);
    mockAxios.restore();
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

    it('calls action to add projects on click if projectTokens have been added', () => {
      const spy = spyOn(vm, 'addProjectsToDashboard');
      vm.$store.state.projectTokens = projectTokens;
      button.click();

      expect(spy).toHaveBeenCalled();
    });

    it('does not call action to add projects on click when projectTokens is empty', () => {
      const spy = spyOn(vm, 'addProjectsToDashboard');
      button.click();

      expect(spy).not.toHaveBeenCalled();
    });
  });

  describe('wrapped components', () => {
    describe('project search component', () => {
      it('renders project search component', () => {
        expect(getChildInstances(vm, ProjectSearchComponent).length).toBe(1);
      });
    });

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
        mockAxios.onGet(mockListPath).replyOnce(200, { data: [] });
        vm = mount();
      });

      it('renders empty state svg after requesting projects with no results', () => {
        const svgSrc = vm.$el
          .querySelector('.js-empty-state-svg')
          .src.slice(-mockText.EMPTY_SVG_SOURCE.length);

        expect(svgSrc).toBe(mockText.EMPTY_SVG_SOURCE);
      });

      it('renders title', () => {
        expect(vm.$el.querySelector('.js-title').innerText.trim()).toBe(mockText.EMPTY_TITLE);
      });

      it('renders sub-title', () => {
        expect(vm.$el.querySelector('.js-sub-title').innerText.trim()).toBe(
          mockText.EMPTY_SUBTITLE,
        );
      });
    });
  });
});
