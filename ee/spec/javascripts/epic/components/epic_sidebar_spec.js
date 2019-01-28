import Vue from 'vue';

import EpicSidebar from 'ee/epic/components/epic_sidebar.vue';
import createStore from 'ee/epic/store';

import epicUtils from 'ee/epic/utils/epic_utils';
import { dateTypes } from 'ee/epic/constants';

import { mountComponentWithStore } from 'spec/helpers/vue_mount_component_helper';
import { mockEpicMeta, mockEpicData } from '../mock_data';

describe('EpicSidebarComponent', () => {
  const originalUserId = gon.current_user_id;
  let vm;
  let store;

  beforeEach(done => {
    const Component = Vue.extend(EpicSidebar);
    store = createStore();
    store.dispatch('setEpicMeta', mockEpicMeta);
    store.dispatch('setEpicData', mockEpicData);

    vm = mountComponentWithStore(Component, {
      store,
    });

    setTimeout(done);
  });

  afterEach(() => {
    vm.$destroy();
  });

  describe('methods', () => {
    describe('getDateFromMilestonesTooltip', () => {
      it('calls `epicUtils.getDateFromMilestonesTooltip` with `dateType` param', () => {
        spyOn(epicUtils, 'getDateFromMilestonesTooltip');

        vm.getDateFromMilestonesTooltip(dateTypes.start);

        expect(epicUtils.getDateFromMilestonesTooltip).toHaveBeenCalledWith(
          jasmine.objectContaining({
            dateType: dateTypes.start,
          }),
        );
      });
    });

    describe('changeStartDateType', () => {
      it('calls `toggleStartDateType` on component with `dateTypeIsFixed` param', () => {
        spyOn(vm, 'toggleStartDateType');

        vm.changeStartDateType(true, true);

        expect(vm.toggleStartDateType).toHaveBeenCalledWith(
          jasmine.objectContaining({
            dateTypeIsFixed: true,
          }),
        );
      });

      it('calls `saveDate` on component when `typeChangeOnEdit` param false', () => {
        spyOn(vm, 'saveDate');

        vm.changeStartDateType(true, false);

        expect(vm.saveDate).toHaveBeenCalledWith(
          jasmine.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.start,
            newDate: '2018-06-01',
          }),
        );
      });
    });

    describe('saveStartDate', () => {
      it('calls `saveDate` on component with `date` param set to `newDate`', () => {
        spyOn(vm, 'saveDate');

        vm.saveStartDate('2018-1-1');

        expect(vm.saveDate).toHaveBeenCalledWith(
          jasmine.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.start,
            newDate: '2018-1-1',
          }),
        );
      });
    });

    describe('changeDueDateType', () => {
      it('calls `toggleDueDateType` on component with `dateTypeIsFixed` param', () => {
        spyOn(vm, 'toggleDueDateType');

        vm.changeDueDateType(true, true);

        expect(vm.toggleDueDateType).toHaveBeenCalledWith(
          jasmine.objectContaining({
            dateTypeIsFixed: true,
          }),
        );
      });

      it('calls `saveDate` on component when `typeChangeOnEdit` param false', () => {
        spyOn(vm, 'saveDate');

        vm.changeDueDateType(true, false);

        expect(vm.saveDate).toHaveBeenCalledWith(
          jasmine.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.due,
            newDate: '2018-08-01',
          }),
        );
      });
    });

    describe('saveDueDate', () => {
      it('calls `saveDate` on component with `date` param set to `newDate`', () => {
        spyOn(vm, 'saveDate');

        vm.saveDueDate('2018-1-1');

        expect(vm.saveDate).toHaveBeenCalledWith(
          jasmine.objectContaining({
            dateTypeIsFixed: true,
            dateType: dateTypes.due,
            newDate: '2018-1-1',
          }),
        );
      });
    });
  });

  describe('template', () => {
    beforeAll(() => {
      gon.current_user_id = 1;
    });

    afterAll(() => {
      gon.current_user_id = originalUserId;
    });

    it('renders component container element with classes `right-sidebar-expanded`, `right-sidebar` & `epic-sidebar`', done => {
      store.dispatch('toggleSidebarFlag', false);

      vm.$nextTick()
        .then(() => {
          expect(vm.$el.classList.contains('right-sidebar-expanded')).toBe(true);
          expect(vm.$el.classList.contains('right-sidebar')).toBe(true);
          expect(vm.$el.classList.contains('epic-sidebar')).toBe(true);
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders header container element with classes `issuable-sidebar` & `js-issuable-update`', () => {
      expect(vm.$el.querySelector('.issuable-sidebar.js-issuable-update')).not.toBeNull();
    });

    it('renders Todo toggle button element when sidebar is collapsed and user is signed in', done => {
      store.dispatch('toggleSidebarFlag', true);

      vm.$nextTick()
        .then(() => {
          const todoBlockEl = vm.$el.querySelector('.block.todo');

          expect(todoBlockEl).not.toBeNull();
          expect(todoBlockEl.querySelector('button.btn-todo')).not.toBeNull();
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders Start date & Due date elements when sidebar is expanded', done => {
      store.dispatch('toggleSidebarFlag', false);

      vm.$nextTick()
        .then(() => {
          const startDateEl = vm.$el.querySelector('.block.date.start-date');
          const dueDateEl = vm.$el.querySelector('.block.date.due-date');

          expect(startDateEl).not.toBeNull();
          expect(startDateEl.querySelector('.title').innerText.trim()).toContain('Start date');
          expect(
            startDateEl.querySelector('.value .value-type-fixed .value-content').innerText.trim(),
          ).toBe('Jun 1, 2018');

          expect(dueDateEl).not.toBeNull();
          expect(dueDateEl.querySelector('.title').innerText.trim()).toContain('Due date');
          expect(
            dueDateEl.querySelector('.value .value-type-fixed .value-content').innerText.trim(),
          ).toBe('Aug 1, 2018');
        })
        .then(done)
        .catch(done.fail);
    });

    it('renders labels select element', () => {
      expect(vm.$el.querySelector('.js-labels-block')).not.toBeNull();
    });
  });
});
