import Vue from 'vue';
import Vuex from 'vuex';
import createStore from 'ee/analytics/cycle_analytics/store';
import { createLocalVue, mount } from '@vue/test-utils';
import CustomStageForm from 'ee/analytics/cycle_analytics/components/custom_stage_form.vue';
import { STAGE_ACTIONS } from 'ee/analytics/cycle_analytics/constants';
import {
  groupLabels,
  customStageEvents as events,
  labelStartEvent,
  labelStopEvent,
  customStageStartEvents as startEvents,
  customStageStopEvents as stopEvents,
  customStageFormErrors,
} from '../mock_data';

const initData = {
  id: 74,
  name: 'Cool stage pre',
  startEventIdentifier: labelStartEvent.identifier,
  startEventLabelId: groupLabels[0].id,
  endEventIdentifier: labelStopEvent.identifier,
  endEventLabelId: groupLabels[1].id,
};

let store = null;
const localVue = createLocalVue();
localVue.use(Vuex);

describe('CustomStageForm', () => {
  function createComponent(props = {}, stubs = {}) {
    store = createStore();
    return mount(CustomStageForm, {
      localVue,
      store,
      propsData: {
        events,
        labels: groupLabels,
        ...props,
      },
      stubs,
    });
  }

  let wrapper = null;
  const findEvent = ev => wrapper.emitted()[ev];

  const sel = {
    name: '[name="custom-stage-name"]',
    startEvent: '[name="custom-stage-start-event"]',
    startEventLabel: '[name="custom-stage-start-event-label"]',
    endEvent: '[name="custom-stage-stop-event"]',
    endEventLabel: '[name="custom-stage-stop-event-label"]',
    submit: '.js-save-stage',
    cancel: '.js-save-stage-cancel',
    invalidFeedback: '.invalid-feedback',
    recoverStageDropdown: '.js-recover-hidden-stage-dropdown',
    recoverStageDropdownTrigger: '.js-recover-hidden-stage-dropdown .dropdown-toggle',
    hiddenStageDropdownOption: '.js-recover-hidden-stage-dropdown .dropdown-item',
  };

  function getDropdownOption(_wrapper, dropdown, index) {
    return _wrapper
      .find(dropdown)
      .findAll('option')
      .at(index);
  }

  function selectDropdownOption(_wrapper, dropdown, index) {
    getDropdownOption(_wrapper, dropdown, index).setSelected();
  }

  function setEventDropdowns({ startEventDropdownIndex = 1, stopEventDropdownIndex = 1 } = {}) {
    selectDropdownOption(wrapper, sel.startEvent, startEventDropdownIndex);
    return Vue.nextTick().then(() => {
      selectDropdownOption(wrapper, sel.endEvent, stopEventDropdownIndex);
    });
  }

  beforeEach(() => {
    wrapper = createComponent({});
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe.each([
    ['Name', sel.name, true],
    ['Start event', sel.startEvent, true],
    ['Stop event', sel.endEvent, false],
    ['Submit', sel.submit, false],
    ['Cancel', sel.cancel, false],
  ])('Default state', (field, $sel, enabledState) => {
    const state = enabledState ? 'enabled' : 'disabled';
    it(`field '${field}' is ${state}`, () => {
      const el = wrapper.find($sel);
      expect(el.exists()).toEqual(true);
      if (!enabledState) {
        expect(el.attributes('disabled')).toEqual('disabled');
      } else {
        expect(el.attributes('disabled')).toBeUndefined();
      }
    });
  });

  describe('Start event', () => {
    describe('with events', () => {
      beforeEach(() => {
        wrapper = createComponent({});
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('selects events with canBeStartEvent=true for the start events dropdown', () => {
        const select = wrapper.find(sel.startEvent);
        expect(select.html()).toMatchSnapshot();
      });

      it('does not select events with canBeStartEvent=false for the start events dropdown', () => {
        const select = wrapper.find(sel.startEvent);
        expect(select.html()).toMatchSnapshot();

        stopEvents
          .filter(ev => !ev.canBeStartEvent)
          .forEach(ev => {
            expect(select.html()).not.toHaveHtml(
              `<option value="${ev.identifier}">${ev.name}</option>`,
            );
          });
      });
    });

    describe('start event label', () => {
      beforeEach(() => {
        wrapper = createComponent();
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('is hidden by default', () => {
        expect(wrapper.find(sel.startEventLabel).exists()).toEqual(false);
      });

      it('will display the start event label field if a label event is selected', () => {
        wrapper.setData({
          fields: {
            startEventIdentifier: labelStartEvent.identifier,
          },
        });

        return Vue.nextTick().then(() => {
          expect(wrapper.find(sel.startEventLabel).exists()).toEqual(true);
        });
      });

      it('will set the "startEventLabelId" field when selected', () => {
        const selectedLabelId = groupLabels[0].id;
        expect(wrapper.vm.fields.startEventLabelId).toEqual(null);

        wrapper.find(sel.startEvent).setValue(labelStartEvent.identifier);
        // TODO: make func for setting single field
        return Vue.nextTick()
          .then(() => {
            wrapper
              .find(sel.startEventLabel)
              .findAll('.dropdown-item')
              .at(1) // item at index 0 is 'select a label'
              .trigger('click');

            return Vue.nextTick();
          })
          .then(() => {
            expect(wrapper.vm.fields.startEventLabelId).toEqual(selectedLabelId);
          });
      });
    });
  });

  describe('Stop event', () => {
    const startEventArrayIndex = 2;
    const startEventDropdownIndex = 1;
    const currAllowed = startEvents[startEventArrayIndex].allowedEndEvents;

    beforeEach(() => {
      wrapper = createComponent();
    });

    it('notifies that a start event needs to be selected first', () => {
      expect(wrapper.text()).toContain('Please select a start event first');
    });

    it('clears notification when a start event is selected', () => {
      selectDropdownOption(wrapper, sel.startEvent, startEventDropdownIndex);
      return Vue.nextTick().then(() => {
        expect(wrapper.text()).not.toContain('Please select a start event first');
      });
    });

    it('is enabled when a start event is selected', () => {
      const el = wrapper.find(sel.endEvent);
      expect(el.attributes('disabled')).toEqual('disabled');

      selectDropdownOption(wrapper, sel.startEvent, startEventDropdownIndex);
      return Vue.nextTick().then(() => {
        expect(el.attributes('disabled')).toBeUndefined();
      });
    });

    it('will update the list of stop events when a start event is changed', () => {
      let stopOptions = wrapper.find(sel.endEvent).findAll('option');
      const selectedStartEvent = startEvents[startEventDropdownIndex];
      expect(stopOptions.length).toEqual(1);

      selectDropdownOption(wrapper, sel.startEvent, startEventDropdownIndex);

      return Vue.nextTick().then(() => {
        stopOptions = wrapper.find(sel.endEvent);
        selectedStartEvent.allowedEndEvents.forEach(identifier => {
          expect(stopOptions.html()).toContain(identifier);
        });
      });
    });

    it('will display all the valid stop events', () => {
      let stopOptions = wrapper.find(sel.endEvent).findAll('option');
      const possibleEndEvents = stopEvents.filter(ev => currAllowed.includes(ev.identifier));

      expect(stopOptions.at(0).html()).toEqual('<option value="">Select stop event</option>');

      selectDropdownOption(wrapper, sel.startEvent, startEventArrayIndex + 1);

      return Vue.nextTick().then(() => {
        stopOptions = wrapper.find(sel.endEvent);

        possibleEndEvents.forEach(({ name, identifier }) => {
          expect(stopOptions.html()).toContain(`<option value="${identifier}">${name}</option>`);
        });
      });
    });

    it('will not display stop events that are not in the list of allowed stop events', () => {
      let stopOptions = wrapper.find(sel.endEvent).findAll('option');
      const excludedEndEvents = stopEvents.filter(ev => !currAllowed.includes(ev.identifier));

      expect(stopOptions.at(0).html()).toEqual('<option value="">Select stop event</option>');

      selectDropdownOption(wrapper, sel.startEvent, startEventArrayIndex + 1);

      return Vue.nextTick().then(() => {
        stopOptions = wrapper.find(sel.endEvent);

        excludedEndEvents.forEach(({ name, identifier }) => {
          expect(wrapper.find(sel.endEvent).html()).not.toHaveHtml(
            `<option value="${identifier}">${name}</option>`,
          );
        });
      });
    });

    describe('with a stop event selected and a change to the start event', () => {
      beforeEach(() => {
        wrapper = createComponent();

        wrapper.setData({
          fields: {
            name: 'Cool stage',
            startEventIdentifier: 'issue_created',
            startEventLabelId: null,
            endEventIdentifier: 'issue_stage_end',
            endEventLabelId: null,
          },
        });
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('will notify if the current start and stop event pair is not valid', () => {
        selectDropdownOption(wrapper, sel.startEvent, 2);

        return Vue.nextTick().then(() => {
          expect(wrapper.find(sel.invalidFeedback).exists()).toEqual(true);
          expect(wrapper.find(sel.invalidFeedback).text()).toContain(
            'Start event changed, please select a valid stop event',
          );
        });
      });

      it('will update the list of stop events', () => {
        const se = wrapper.vm.endEventOptions;
        selectDropdownOption(wrapper, sel.startEvent, 2);
        return Vue.nextTick().then(() => {
          expect(se[1].value).not.toEqual(wrapper.vm.endEventOptions[1].value);
        });
      });

      it('will disable the submit button until a valid endEvent is selected', () => {
        selectDropdownOption(wrapper, sel.startEvent, 2);
        return Vue.nextTick().then(() => {
          expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
        });
      });
    });

    describe('Stop event label', () => {
      beforeEach(() => {
        wrapper = createComponent({});
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('is hidden by default', () => {
        expect(wrapper.find(sel.startEventLabel).exists()).toEqual(false);
      });

      it('will display the stop event label field if a label event is selected', () => {
        expect(wrapper.find(sel.endEventLabel).exists()).toEqual(false);

        wrapper.setData({
          fields: {
            endEventIdentifier: labelStopEvent.identifier,
            startEventIdentifier: labelStartEvent.identifier,
          },
        });

        return Vue.nextTick().then(() => {
          expect(wrapper.find(sel.endEventLabel).exists()).toEqual(true);
        });
      });

      it('will set the "endEventLabelId" field when selected', () => {
        const selectedLabelId = groupLabels[1].id;
        expect(wrapper.vm.fields.endEventLabelId).toEqual(null);

        wrapper.setData({
          fields: {
            startEventIdentifier: labelStartEvent.identifier,
            endEventIdentifier: labelStopEvent.identifier,
          },
        });

        return Vue.nextTick()
          .then(() => {
            wrapper
              .find(sel.endEventLabel)
              .findAll('.dropdown-item')
              .at(2) // item at index 0 is 'select a label'
              .trigger('click');

            return Vue.nextTick();
          })
          .then(() => {
            expect(wrapper.vm.fields.endEventLabelId).toEqual(selectedLabelId);
          });
      });
    });
  });

  describe('Add stage button', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('has text `Add stage`', () => {
      expect(wrapper.find(sel.submit).text()).toEqual('Add stage');
    });

    it('is enabled when all required fields are filled', () => {
      const btn = wrapper.find(sel.submit);

      expect(btn.attributes('disabled')).toEqual('disabled');
      wrapper.find(sel.name).setValue('Cool stage');

      return setEventDropdowns().then(() => {
        expect(btn.attributes('disabled')).toBeUndefined();
      });
    });

    describe('with all fields set', () => {
      const startEventDropdownIndex = 2;
      const startEventArrayIndex = startEventDropdownIndex - 1;
      const stopEventDropdownIndex = 1;

      beforeEach(() => {
        wrapper = createComponent({});
        wrapper.find(sel.name).setValue('Cool stage');
        return Vue.nextTick().then(() =>
          setEventDropdowns({ startEventDropdownIndex, stopEventDropdownIndex }),
        );
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it(`emits a ${STAGE_ACTIONS.CREATE} event when clicked`, () => {
        let event = findEvent(STAGE_ACTIONS.CREATE);
        expect(event).toBeUndefined();

        wrapper.find(sel.submit).trigger('click');

        return Vue.nextTick().then(() => {
          event = findEvent(STAGE_ACTIONS.CREATE);
          expect(event).toBeTruthy();
          expect(event.length).toEqual(1);
        });
      });

      it(`${STAGE_ACTIONS.CREATE} event receives the latest data`, () => {
        const startEv = startEvents[startEventArrayIndex];
        const selectedStopEvent = getDropdownOption(wrapper, sel.endEvent, stopEventDropdownIndex);
        let event = findEvent(STAGE_ACTIONS.CREATE);
        expect(event).toBeUndefined();

        const res = [
          {
            id: null,
            name: 'Cool stage',
            start_event_identifier: startEv.identifier,
            start_event_label_id: null,
            end_event_identifier: selectedStopEvent.attributes('value'),
            end_event_label_id: null,
          },
        ];

        wrapper.find(sel.submit).trigger('click');
        return Vue.nextTick().then(() => {
          event = findEvent(STAGE_ACTIONS.CREATE);
          expect(event[0]).toEqual(res);
        });
      });
    });
  });

  describe('Cancel button', () => {
    beforeEach(() => {
      wrapper = createComponent({});
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('is enabled when the form is dirty', () => {
      const btn = wrapper.find(sel.cancel);

      expect(btn.attributes('disabled')).toEqual('disabled');
      wrapper.find(sel.name).setValue('Cool stage');

      return Vue.nextTick().then(() => {
        expect(btn.attributes('disabled')).toBeUndefined();
      });
    });

    it('will reset the fields when clicked', () => {
      wrapper.setData({
        fields: {
          name: 'Cool stage pre',
          startEventIdentifier: labelStartEvent.identifier,
          endEventIdentifier: labelStopEvent.identifier,
        },
      });

      return Vue.nextTick()
        .then(() => {
          wrapper.find(sel.cancel).trigger('click');

          return Vue.nextTick();
        })
        .then(() => {
          expect(wrapper.vm.fields).toEqual({
            id: null,
            name: null,
            startEventIdentifier: null,
            startEventLabelId: null,
            endEventIdentifier: null,
            endEventLabelId: null,
          });
        });
    });

    it('will emit the `cancel` event when clicked', () => {
      let ev = findEvent('cancel');
      expect(ev).toBeUndefined();

      wrapper.setData({
        fields: {
          name: 'Cool stage pre',
        },
      });

      return Vue.nextTick()
        .then(() => {
          wrapper.find(sel.cancel).trigger('click');
          return Vue.nextTick();
        })
        .then(() => {
          ev = findEvent('cancel');
          expect(ev).toBeTruthy();
          expect(ev.length).toEqual(1);
        });
    });
  });

  describe('isSavingCustomStage=true', () => {
    beforeEach(() => {
      wrapper = createComponent(
        {
          isSavingCustomStage: true,
        },
        false,
      );
    });

    it('displays a loading icon', () => {
      expect(wrapper.find(sel.submit).html()).toMatchSnapshot();
    });
  });

  describe('Editing a custom stage', () => {
    beforeEach(() => {
      wrapper = createComponent({
        isEditingCustomStage: true,
        initialFields: {
          ...initData,
        },
      });

      wrapper.setData({
        fields: {
          ...initData,
        },
      });

      return Vue.nextTick();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe('Cancel button', () => {
      it('will reset the fields to initial state when clicked', () => {
        wrapper.setData({
          fields: {
            name: 'Cool stage pre',
            startEventIdentifier: labelStartEvent.identifier,
            endEventIdentifier: labelStopEvent.identifier,
          },
        });

        return Vue.nextTick()
          .then(() => {
            wrapper.find(sel.cancel).trigger('click');
            return Vue.nextTick();
          })
          .then(() => {
            expect(wrapper.vm.fields).toEqual({ ...initData });
          });
      });
    });

    describe('Update stage button', () => {
      it('has text `Update stage`', () => {
        expect(wrapper.find(sel.submit).text('value')).toEqual('Update stage');
      });

      it('is disabled by default', () => {
        expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
      });

      it('is enabled when a field is changed and fields are valid', () => {
        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        return Vue.nextTick().then(() => {
          expect(wrapper.find(sel.submit).attributes('disabled')).toBeUndefined();
        });
      });

      it('is disabled when a field is changed but fields are incomplete', () => {
        wrapper.setData({
          fields: {
            name: '',
          },
        });

        return Vue.nextTick().then(() => {
          expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
        });
      });

      it(`emits a ${STAGE_ACTIONS.UPDATE} event when clicked`, () => {
        let ev = findEvent(STAGE_ACTIONS.UPDATE);
        expect(ev).toBeUndefined();

        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        return Vue.nextTick()
          .then(() => {
            wrapper.find(sel.submit).trigger('click');
            return Vue.nextTick();
          })
          .then(() => {
            ev = findEvent(STAGE_ACTIONS.UPDATE);
            expect(ev).toBeTruthy();
            expect(ev.length).toEqual(1);
          });
      });

      it('`submit` event receives the latest data', () => {
        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        return Vue.nextTick()
          .then(() => {
            wrapper.find(sel.submit).trigger('click');
            return Vue.nextTick();
          })
          .then(() => {
            const submitted = findEvent(STAGE_ACTIONS.UPDATE)[0];
            expect(submitted).not.toEqual([initData]);
            expect(submitted).toEqual([
              {
                id: initData.id,
                start_event_identifier: labelStartEvent.identifier,
                start_event_label_id: groupLabels[0].id,
                end_event_identifier: labelStopEvent.identifier,
                end_event_label_id: groupLabels[1].id,
                name: 'Cool updated form',
              },
            ]);
          });
      });
    });

    describe('isSavingCustomStage=true', () => {
      beforeEach(() => {
        wrapper = createComponent({
          isEditingCustomStage: true,
          initialFields: {
            ...initData,
          },
          isSavingCustomStage: true,
        });
      });
      it('displays a loading icon', () => {
        expect(wrapper.find(sel.submit).html()).toMatchSnapshot();
      });
    });
  });

  describe('With errors', () => {
    beforeEach(() => {
      wrapper = createComponent({
        initialFields: initData,
        errors: customStageFormErrors,
      });

      return Vue.nextTick();
    });

    afterEach(() => {
      wrapper.destroy();
    });

    it('renders the errors for the relevant fields', () => {
      expect(wrapper.find({ ref: 'name' }).html()).toContain('is reserved');
      expect(wrapper.find({ ref: 'name' }).html()).toContain('cant be blank');
      expect(wrapper.find({ ref: 'startEventIdentifier' }).html()).toContain('cant be blank');
    });
  });

  describe('recover stage dropdown', () => {
    const formFieldStubs = {
      'gl-form-group': true,
      'gl-form-select': true,
      'labels-selector': true,
    };

    beforeEach(() => {
      wrapper = createComponent({}, formFieldStubs);
    });

    describe('without hidden stages', () => {
      it('has the recover stage dropdown', () => {
        expect(wrapper.find(sel.recoverStageDropdown).exists()).toBe(true);
      });

      it('has no stages available to recover', () => {
        wrapper.find(sel.recoverStageDropdownTrigger).trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          expect(wrapper.find(sel.recoverStageDropdown).text()).toContain(
            'All default stages are currently visible',
          );
        });
      });
    });

    describe('with hidden stages', () => {
      beforeEach(() => {
        wrapper = createComponent({}, formFieldStubs);
        store.state.stages = [{ id: 'my-stage', title: 'My default stage', hidden: true }];
      });

      it('has stages available to recover', () => {
        wrapper.find(sel.recoverStageDropdownTrigger).trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          const txt = wrapper.find(sel.recoverStageDropdown).text();
          expect(txt).not.toContain('All default stages are currently visible');
          expect(txt).toContain('My default stage');
        });
      });

      it(`emits the ${STAGE_ACTIONS.UPDATE} action when clicking on a stage to recover`, () => {
        wrapper.find(sel.recoverStageDropdownTrigger).trigger('click');
        return wrapper.vm.$nextTick().then(() => {
          wrapper
            .findAll(sel.hiddenStageDropdownOption)
            .at(0)
            .trigger('click');

          expect(wrapper.emitted()).toEqual({
            [STAGE_ACTIONS.UPDATE]: [[{ hidden: false, id: 'my-stage' }]],
          });
        });
      });
    });
  });
});
