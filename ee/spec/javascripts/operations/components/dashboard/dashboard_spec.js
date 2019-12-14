import MockAdapter from 'axios-mock-adapter';
import { mount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import Project from 'ee/operations/components/dashboard/project.vue';
import Dashboard from 'ee/operations/components/dashboard/dashboard.vue';
import createStore from 'ee/vue_shared/dashboards/store';
import timeoutPromise from 'spec/helpers/set_timeout_promise_helper';
import { trimText } from 'spec/helpers/text_helper';
import axios from '~/lib/utils/axios_utils';
import { mockProjectData, mockText } from '../../mock_data';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('dashboard component', () => {
  const mockAddEndpoint = 'mock-addPath';
  const mockListEndpoint = 'mock-listPath';
  const DashboardComponent = localVue.extend(Dashboard);
  const store = createStore();
  let wrapper;
  let mockAxios;

  const mountComponent = () =>
    mount(DashboardComponent, {
      sync: false,
      store,
      localVue,
      propsData: {
        addPath: mockAddEndpoint,
        listPath: mockListEndpoint,
        emptyDashboardSvgPath: '/assets/illustrations/operations-dashboard_empty.svg',
        emptyDashboardHelpPath: '/help/user/operations_dashboard/index.html',
      },
    });

  beforeEach(() => {
    mockAxios = new MockAdapter(axios);
    mockAxios.onGet(mockListEndpoint).replyOnce(200, { projects: mockProjectData(1) });
    wrapper = mountComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    mockAxios.restore();
  });

  it('renders dashboard title', () => {
    const dashboardTitle = wrapper.element.querySelector('.js-dashboard-title');

    expect(dashboardTitle.innerText.trim()).toEqual(mockText.DASHBOARD_TITLE);
  });

  describe('add projects button', () => {
    let button;

    beforeEach(() => {
      button = wrapper.element.querySelector('.js-add-projects-button');
    });

    it('renders add projects text', () => {
      expect(button.innerText.trim()).toBe(mockText.ADD_PROJECTS);
    });

    it('renders the projects modal', () => {
      button.click();

      expect(wrapper.element.querySelector('.add-projects-modal')).toBeDefined();
    });

    describe('when a project is added', () => {
      it('immediately requests the project list again', done => {
        mockAxios.reset();
        mockAxios.onGet(mockListEndpoint).replyOnce(200, { projects: mockProjectData(2) });
        mockAxios.onPost(mockAddEndpoint).replyOnce(200, { added: [1], invalid: [] });
        wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.projectClicked({ id: 1 });
          })
          .then(timeoutPromise)
          .then(() => {
            wrapper.vm.onOk();
          })
          .then(timeoutPromise)
          .then(() => {
            expect(store.state.projects.length).toEqual(2);
            expect(wrapper.findAll(Project).length).toEqual(2);
            done();
          })
          .catch(done.fail);
      });
    });
  });

  describe('wrapped components', () => {
    describe('dashboard project component', () => {
      const projectCount = 1;

      beforeEach(() => {
        const projects = mockProjectData(projectCount);
        store.state.projects = projects;
        wrapper = mountComponent();
      });

      it('includes a dashboard project component for each project', () => {
        const projectComponents = wrapper.findAll(Project);

        expect(projectComponents.length).toBe(projectCount);
      });

      it('passes each project to the dashboard project component', () => {
        const [oneProject] = store.state.projects;
        const projectComponent = wrapper.find(Project);

        expect(projectComponent.props().project).toEqual(oneProject);
      });

      it('dispatches setProjects when projects changes', () => {
        const dispatch = spyOn(wrapper.vm.$store, 'dispatch');
        const projects = mockProjectData(3);

        wrapper.vm.projects = projects;

        expect(dispatch).toHaveBeenCalledWith('setProjects', projects);
      });

      describe('when a project is removed', () => {
        it('immediately requests the project list again', done => {
          mockAxios.reset();
          mockAxios.onDelete(store.state.projects[0].remove_path).reply(200);
          mockAxios.onGet(mockListEndpoint).replyOnce(200, { projects: [] });

          wrapper.find('button.js-remove-button').vm.$emit('click');

          timeoutPromise()
            .then(() => {
              expect(store.state.projects.length).toEqual(0);
              expect(wrapper.findAll(Project).length).toEqual(0);
              done();
            })
            .catch(done.fail);
        });
      });
    });

    describe('add projects modal', () => {
      beforeEach(() => {
        store.state.projectSearchResults = mockProjectData(2);
        store.state.selectedProjects = mockProjectData(1);
      });

      it('clears state when adding a valid project', done => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(200, { added: [1], invalid: [] });
        wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.onOk();
          })
          .then(timeoutPromise)
          .then(() => {
            expect(store.state.projectSearchResults.length).toEqual(0);
            expect(store.state.selectedProjects.length).toEqual(0);
            done();
          })
          .catch(done.fail);
      });

      it('clears state when adding an invalid project', done => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(200, { added: [], invalid: [1] });
        wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.onOk();
          })
          .then(timeoutPromise)
          .then(() => {
            expect(store.state.projectSearchResults.length).toEqual(0);
            expect(store.state.selectedProjects.length).toEqual(0);
            done();
          })
          .catch(done.fail);
      });

      it('clears state when canceled', done => {
        wrapper.vm
          .$nextTick()
          .then(() => {
            wrapper.vm.onCancel();
          })
          .then(timeoutPromise)
          .then(() => {
            expect(store.state.projectSearchResults.length).toEqual(0);
            expect(store.state.selectedProjects.length).toEqual(0);
            done();
          })
          .catch(done.fail);
      });

      it('clears state on error', done => {
        mockAxios.onPost(mockAddEndpoint).replyOnce(500, {});
        wrapper.vm
          .$nextTick()
          .then(() => {
            expect(store.state.projectSearchResults.length).not.toEqual(0);
            expect(store.state.selectedProjects.length).not.toEqual(0);
            wrapper.vm.onOk();
          })
          .then(timeoutPromise)
          .then(() => {
            expect(store.state.projectSearchResults.length).toEqual(0);
            expect(store.state.selectedProjects.length).toEqual(0);
            done();
          })
          .catch(done.fail);
      });
    });

    describe('empty state', () => {
      beforeEach(() => {
        store.state.projects = [];
        mockAxios.reset();
        mockAxios.onGet(mockListEndpoint).replyOnce(200, { projects: [] });
        wrapper = mountComponent();
      });

      it('renders empty state svg after requesting projects with no results', () => {
        const svgSrc = wrapper.element.querySelector('.js-empty-state-svg').src;

        expect(svgSrc).toMatch(mockText.EMPTY_SVG_SOURCE);
      });

      it('renders title', () => {
        expect(wrapper.element.querySelector('.js-title').innerText.trim()).toBe(
          mockText.EMPTY_TITLE,
        );
      });

      it('renders sub-title', () => {
        expect(trimText(wrapper.element.querySelector('.js-sub-title').innerText)).toBe(
          mockText.EMPTY_SUBTITLE,
        );
      });

      it('renders link to documentation', () => {
        const link = wrapper.element.querySelector('.js-documentation-link');

        expect(link.innerText.trim()).toBe('More information');
      });

      it('links to documentation', () => {
        const link = wrapper.element.querySelector('.js-documentation-link');

        expect(link.href).toMatch(wrapper.props().emptyDashboardHelpPath);
      });
    });
  });
});
