import { shallowMount } from '@vue/test-utils';
import { GlNewDropdownItem, GlModal, GlLoadingIcon, GlAlert } from '@gitlab/ui';
import waitForPromises from 'helpers/wait_for_promises';
import * as types from '~/monitoring/stores/mutation_types';

import DashboardsDropdown from '~/monitoring/components/dashboards_dropdown.vue';
import DuplicateDashboardForm from '~/monitoring/components/duplicate_dashboard_form.vue';
import { createStore } from '~/monitoring/stores';

import { dashboardGitResponse } from '../mock_data';

const defaultBranch = 'master';

describe('DashboardsDropdown', () => {
  let wrapper;
  let store;

  function createComponent(props, opts = {}) {
    return shallowMount(DashboardsDropdown, {
      propsData: {
        ...props,
        defaultBranch,
      },
      store,
      ...opts,
    });
  }

  const findItems = () => wrapper.findAll(GlNewDropdownItem);
  const findItemAt = i => wrapper.findAll(GlNewDropdownItem).at(i);
  const findSearchInput = () => wrapper.find({ ref: 'monitorDashboardsDropdownSearch' });
  const findNoItemsMsg = () => wrapper.find({ ref: 'monitorDashboardsDropdownMsg' });
  const setSearchTerm = searchTerm => wrapper.setData({ searchTerm });

  beforeEach(() => {
    store = createStore();
    store.commit(`monitoringDashboard/${types.SET_ALL_DASHBOARDS}`, dashboardGitResponse);

    jest.spyOn(store, 'dispatch');
  });

  describe('when it receives dashboards data', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('displays an item for each dashboard', () => {
      expect(findItems().length).toEqual(dashboardGitResponse.length);
    });

    it('displays items with the dashboard display name', () => {
      expect(findItemAt(0).text()).toBe(dashboardGitResponse[0].display_name);
      expect(findItemAt(1).text()).toBe(dashboardGitResponse[1].display_name);
      expect(findItemAt(2).text()).toBe(dashboardGitResponse[2].display_name);
    });

    it('displays items with a star for starred dashboards', () => {
      expect(findItemAt(0).props('iconRightName')).toBe(null);
      expect(findItemAt(1).props('iconRightName')).toBe('star');
    });

    it('displays a search input', () => {
      expect(findSearchInput().isVisible()).toBe(true);
    });

    it('hides no message text by default', () => {
      expect(findNoItemsMsg().isVisible()).toBe(false);
    });

    it('filters dropdown items when searched for item exists in the list', () => {
      const searchTerm = 'Default';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick(() => {
        expect(findItems()).toHaveLength(1);
      });
    });

    it('shows no items found message when searched for item does not exists in the list', () => {
      const searchTerm = 'does-not-exist';
      setSearchTerm(searchTerm);

      return wrapper.vm.$nextTick(() => {
        expect(findNoItemsMsg().isVisible()).toBe(true);
      });
    });
  });

  describe('when a system dashboard is selected', () => {
    let modalDirective;

    beforeEach(() => {
      modalDirective = jest.fn();

      wrapper = createComponent(
        {
          selectedDashboard: dashboardGitResponse[0],
        },
        {
          directives: {
            GlModal: modalDirective,
          },
        },
      );

      wrapper.vm.$refs.duplicateDashboardModal.hide = jest.fn();
    });

    it('displays an item for each dashboard plus a "duplicate dashboard" item', () => {
      const item = wrapper.findAll({ ref: 'duplicateDashboardItem' });

      expect(findItems().length).toEqual(dashboardGitResponse.length + 1);
      expect(item.length).toBe(1);
    });

    describe('modal form', () => {
      let okEvent;

      const findModal = () => wrapper.find(GlModal);
      const findAlert = () => wrapper.find(GlAlert);
      const newDashboard = {
        can_edit: true,
        default: false,
        display_name: 'A new dashboard',
        system_dashboard: false,
      };

      beforeEach(() => {
        store.dispatch.mockImplementation(action => {
          if (action === 'monitoringDashboard/duplicateSystemDashboard') {
            return Promise.resolve(newDashboard);
          }
          throw new Error('Not implemented');
        });

        okEvent = {
          preventDefault: jest.fn(),
        };
      });

      it('exists and contains a form to duplicate a dashboard', () => {
        expect(findModal().exists()).toBe(true);
        expect(findModal().contains(DuplicateDashboardForm)).toBe(true);
      });

      it('saves a new dashboard', () => {
        findModal().vm.$emit('ok', okEvent);

        return waitForPromises().then(() => {
          expect(okEvent.preventDefault).toHaveBeenCalled();

          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
          expect(wrapper.vm.$refs.duplicateDashboardModal.hide).toHaveBeenCalled();
          expect(wrapper.emitted().selectDashboard).toBeTruthy();
          expect(findAlert().exists()).toBe(false);
        });
      });

      describe('when a new dashboard is saved succesfully', () => {
        const submitForm = formVals => {
          findModal()
            .find(DuplicateDashboardForm)
            .vm.$emit('change', {
              dashboard: 'common_metrics.yml',
              commitMessage: 'A commit message',
              ...formVals,
            });
          findModal().vm.$emit('ok', okEvent);
        };

        it('to the default branch, redirects to the new dashboard', () => {
          submitForm({
            branch: defaultBranch,
          });

          return waitForPromises().then(() => {
            expect(wrapper.emitted().selectDashboard[0][0]).toEqual(newDashboard);
          });
        });

        it('to a new branch refreshes in the current dashboard', () => {
          submitForm({
            branch: 'another-branch',
          });

          return waitForPromises().then(() => {
            expect(wrapper.emitted().selectDashboard[0][0]).toEqual(dashboardGitResponse[0]);
          });
        });
      });

      it('handles error when a new dashboard is not saved', () => {
        const errMsg = 'An error occurred';

        store.dispatch.mockImplementationOnce(action => {
          if (action === 'monitoringDashboard/duplicateSystemDashboard') {
            return Promise.reject(errMsg);
          }
          throw new Error('Not implemented');
        });

        findModal().vm.$emit('ok', okEvent);

        return waitForPromises().then(() => {
          expect(okEvent.preventDefault).toHaveBeenCalled();

          expect(findAlert().exists()).toBe(true);
          expect(findAlert().text()).toBe(errMsg);

          expect(wrapper.find(GlLoadingIcon).exists()).toBe(false);
          expect(wrapper.vm.$refs.duplicateDashboardModal.hide).not.toHaveBeenCalled();
        });
      });

      it('id is correct, as the value of modal directive binding matches modal id', () => {
        expect(modalDirective).toHaveBeenCalledTimes(1);

        // Binding's second argument contains the modal id
        expect(modalDirective.mock.calls[0][1]).toEqual(
          expect.objectContaining({
            value: findModal().props('modalId'),
          }),
        );
      });

      it('updates the form on changes', () => {
        const formVals = {
          dashboard: 'common_metrics.yml',
          commitMessage: 'A commit message',
        };

        findModal()
          .find(DuplicateDashboardForm)
          .vm.$emit('change', formVals);

        // Binding's second argument contains the modal id
        expect(wrapper.vm.form).toEqual(formVals);
      });
    });
  });

  describe('when a custom dashboard is selected', () => {
    const findModal = () => wrapper.find(GlModal);

    beforeEach(() => {
      wrapper = createComponent({
        selectedDashboard: dashboardGitResponse[1],
      });
    });

    it('displays an item for each dashboard', () => {
      const item = wrapper.findAll({ ref: 'duplicateDashboardItem' });

      expect(findItems()).toHaveLength(dashboardGitResponse.length);
      expect(item.length).toBe(0);
    });

    it('modal form does not exist and contains a form to duplicate a dashboard', () => {
      expect(findModal().exists()).toBe(false);
    });
  });

  describe('when a dashboard gets selected by the user', () => {
    beforeEach(() => {
      wrapper = createComponent();
      findItemAt(1).vm.$emit('click');
    });

    it('emits a "selectDashboard" event', () => {
      expect(wrapper.emitted().selectDashboard).toBeTruthy();
    });
    it('emits a "selectDashboard" event with dashboard information', () => {
      expect(wrapper.emitted().selectDashboard[0]).toEqual([dashboardGitResponse[1]]);
    });
  });
});
