import Vuex from 'vuex';
import SecurityDashboardTableRow from 'ee/security_dashboard/components/security_dashboard_table_row.vue';
import createStore from 'ee/security_dashboard/store';
import { mount, shallowMount, createLocalVue } from '@vue/test-utils';
import mockDataVulnerabilities from '../store/vulnerabilities/data/mock_data_vulnerabilities';
import { DASHBOARD_TYPES } from 'ee/security_dashboard/store/constants';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('Security Dashboard Table Row', () => {
  let wrapper;
  let store;

  const createComponent = (mountFunc, { props = {}, storeParams = {} } = {}) => {
    store = createStore(storeParams);
    wrapper = mountFunc(SecurityDashboardTableRow, {
      localVue,
      store,
      propsData: {
        ...props,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findLoader = () => wrapper.find('.js-skeleton-loader');
  const findContent = i => wrapper.findAll('.table-mobile-content').at(i);
  const findAllIssueCreated = () => wrapper.findAll('.ic-issue-created');

  describe('when loading', () => {
    beforeEach(() => {
      createComponent(shallowMount, { props: { isLoading: true } });
    });

    it('should display the skeleton loader', () => {
      expect(findLoader().exists()).toBeTruthy();
    });

    it('should render a ` ` for severity', () => {
      expect(wrapper.vm.severity).toEqual(' ');
      expect(findContent(0).text()).toEqual('');
    });

    it('should not render action buttons', () => {
      expect(wrapper.findAll('.action-buttons button').length).toBe(0);
    });
  });

  describe('when loaded', () => {
    let vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should not display the skeleton loader', () => {
      expect(findLoader().exists()).toBeFalsy();
    });

    it('should render the severity', () => {
      expect(
        findContent(0)
          .text()
          .toLowerCase(),
      ).toContain(wrapper.props().vulnerability.severity);
    });

    describe('the project name', () => {
      it('should render the name', () => {
        expect(findContent(1).text()).toContain(wrapper.props().vulnerability.name);
      });

      it('should render the project namespace', () => {
        expect(findContent(1).text()).toContain(wrapper.props().vulnerability.location.file);
      });

      it('should fire the openModal action when clicked', () => {
        jest.spyOn(store, 'dispatch').mockImplementation();

        const el = wrapper.find('.vulnerability-title');
        el.trigger('click');

        expect(store.dispatch).toHaveBeenCalledWith('vulnerabilities/openModal', {
          vulnerability,
        });
      });
    });

    describe('Group Security Dashboard', () => {
      beforeEach(() => {
        createComponent(shallowMount, {
          props: { vulnerability },
          storeParams: { dashboardType: DASHBOARD_TYPES.GROUP },
        });
      });

      it('should contain project name as the namespace', () => {
        expect(findContent(1).text()).toContain(wrapper.props().vulnerability.project.full_name);
      });
    });

    describe('Non-group Security Dashboard', () => {
      beforeEach(() => {
        // eslint-disable-next-line prefer-destructuring
        vulnerability = mockDataVulnerabilities[7];

        createComponent(shallowMount, { props: { vulnerability } });
      });

      it('should contain container image as the namespace', () => {
        expect(findContent(1).text()).toContain(wrapper.props().vulnerability.location.image);
      });
    });
  });

  describe('with a dismissed vulnerability', () => {
    const vulnerability = mockDataVulnerabilities[2];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should have a `dismissed` class', () => {
      expect(wrapper.classes()).toContain('dismissed');
    });

    it('should render a `DISMISSED` tag', () => {
      expect(wrapper.text()).toContain('dismissed');
    });
  });

  describe('with valid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[3];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should have a `ic-issue-created` class', () => {
      expect(findAllIssueCreated()).toHaveLength(1);
    });
  });

  describe('with invalid issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[6];

    beforeEach(() => {
      createComponent(mount, { props: { vulnerability } });
    });

    it('should not have a `ic-issue-created` class', () => {
      expect(findAllIssueCreated()).toHaveLength(0);
    });
  });

  describe('with no issue feedback', () => {
    const vulnerability = mockDataVulnerabilities[0];

    beforeEach(() => {
      createComponent(shallowMount, { props: { vulnerability } });
    });

    it('should not have a `ic-issue-created` class', () => {
      expect(findAllIssueCreated()).toHaveLength(0);
    });
  });
});
