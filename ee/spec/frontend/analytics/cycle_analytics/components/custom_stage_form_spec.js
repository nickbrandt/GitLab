import Vue from 'vue';
import { mount } from '@vue/test-utils';
import CustomStageForm from 'ee/analytics/cycle_analytics/components/custom_stage_form.vue';
import {
  groupLabels,
  customStageEvents as events,
  labelStartEvent,
  labelStopEvent,
  customStageStartEvents as startEvents,
  customStageStopEvents as stopEvents,
} from '../mock_data';

const initData = {
  name: 'Cool stage pre',
  startEvent: labelStartEvent.identifier,
  startEventLabel: groupLabels[0].id,
  stopEvent: labelStopEvent.identifier,
  stopEventLabel: groupLabels[1].id,
};

describe('CustomStageForm', () => {
  function createComponent(props) {
    return mount(CustomStageForm, {
      propsData: {
        events,
        labels: groupLabels,
        ...props,
      },
      sync: false,
    });
  }

  let wrapper = null;

  const sel = {
    name: '[name="custom-stage-name"]',
    startEvent: '[name="custom-stage-start-event"]',
    startEventLabel: '[name="custom-stage-start-event-label"]',
    stopEvent: '[name="custom-stage-stop-event"]',
    stopEventLabel: '[name="custom-stage-stop-event-label"]',
    submit: '.js-custom-stage-form-submit',
    cancel: '.js-custom-stage-form-cancel',
    invalidFeedback: '.invalid-feedback',
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

  describe('Empty form', () => {
    beforeEach(() => {
      wrapper = createComponent({}, false);
    });

    afterEach(() => {
      wrapper.destroy();
    });

    describe.each([
      ['Name', sel.name, true],
      ['Start event', sel.startEvent, true],
      ['Stop event', sel.stopEvent, false],
      ['Submit', sel.submit, false],
      ['Cancel', sel.cancel, false],
    ])('by default', (field, $sel, enabledState) => {
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
          wrapper = createComponent({}, false);
        });

        afterEach(() => {
          wrapper.destroy();
        });

        it('selects events with canBeStartEvent=true for the start events dropdown', () => {
          const select = wrapper.find(sel.startEvent);

          startEvents.forEach(ev => {
            expect(select.html()).toHaveHtml(
              `<option value="${ev.identifier}">${ev.name}</option>`,
            );
          });
        });
      });

      describe('start event label', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);
        });

        afterEach(() => {
          wrapper.destroy();
        });

        it('is hidden by default', () => {
          expect(wrapper.find(sel.startEventLabel).exists()).toEqual(false);
        });

        it('will display the start event label field if a label event is selected', done => {
          wrapper.setData({
            fields: {
              startEvent: labelStartEvent.identifier,
            },
          });

          Vue.nextTick(() => {
            expect(wrapper.find(sel.startEventLabel).exists()).toEqual(true);
            done();
          });
        });

        it('will set the "startEventLabel" field when selected', done => {
          const selectedLabelId = groupLabels[0].id;
          expect(wrapper.vm.fields.startEventLabel).toEqual(null);

          wrapper.find(sel.startEvent).setValue(labelStartEvent.identifier);
          Vue.nextTick(() => {
            wrapper
              .find(sel.startEventLabel)
              .findAll('.dropdown-item')
              .at(1) // item at index 0 is 'select a label'
              .trigger('click');

            Vue.nextTick(() => {
              expect(wrapper.vm.fields.startEventLabel).toEqual(selectedLabelId);
              done();
            });
          });
        });
      });
    });

    describe('Stop event', () => {
      const index = 2;
      const currAllowed = startEvents[index].allowedEndEvents;

      beforeEach(() => {
        wrapper = createComponent({}, false);
      });

      it('notifies that a start event needs to be selected first', () => {
        expect(wrapper.text()).toContain('Please select a start event first');
      });

      it('clears notification when a start event is selected', done => {
        selectDropdownOption(wrapper, sel.startEvent, 1);
        Vue.nextTick(() => {
          expect(wrapper.text()).not.toContain('Please select a start event first');
          done();
        });
      });

      it('is enabled when a start event is selected', done => {
        const el = wrapper.find(sel.stopEvent);
        expect(el.attributes('disabled')).toEqual('disabled');

        selectDropdownOption(wrapper, sel.startEvent, 1);
        Vue.nextTick(() => {
          expect(el.attributes('disabled')).toBeUndefined();
          done();
        });
      });

      it('will update the list of stop events when a start event is changed', done => {
        let stopOptions = wrapper.find(sel.stopEvent).findAll('option');
        const selectedStartEventIndex = 1;
        const selectedStartEvent = startEvents[selectedStartEventIndex];
        expect(stopOptions.length).toEqual(1);

        selectDropdownOption(wrapper, sel.startEvent, selectedStartEventIndex);

        Vue.nextTick(() => {
          stopOptions = wrapper.find(sel.stopEvent);
          selectedStartEvent.allowedEndEvents.forEach(identifier => {
            expect(stopOptions.html()).toContain(identifier);
          });
          done();
        });
      });

      it('will display all the valid stop events', done => {
        let stopOptions = wrapper.find(sel.stopEvent).findAll('option');
        const possibleEndEvents = stopEvents.filter(ev => currAllowed.includes(ev.identifier));

        expect(stopOptions.at(0).html()).toEqual('<option value="">Select stop event</option>');

        selectDropdownOption(wrapper, sel.startEvent, index);

        Vue.nextTick(() => {
          stopOptions = wrapper.find(sel.stopEvent);

          possibleEndEvents.forEach(({ name, identifier }) => {
            expect(stopOptions.html()).toContain(`<option value="${identifier}">${name}</option>`);
          });
          done();
        });
      });

      it('will not display stop events that are not in the list of allowed stop events', done => {
        let stopOptions = wrapper.find(sel.stopEvent).findAll('option');
        const excludedEndEvents = stopEvents.filter(ev => !currAllowed.includes(ev.identifier));

        expect(stopOptions.at(0).html()).toEqual('<option value="">Select stop event</option>');

        selectDropdownOption(wrapper, sel.startEvent, index);

        Vue.nextTick(() => {
          stopOptions = wrapper.find(sel.stopEvent);

          excludedEndEvents.forEach(({ name, identifier }) => {
            expect(wrapper.find(sel.stopEvent).html()).not.toHaveHtml(
              `<option value="${identifier}">${name}</option>`,
            );
          });
          done();
        });
      });

      describe('with a stop event selected and a change to the start event', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);

          wrapper.setData({
            fields: {
              name: 'Cool stage',
              startEvent: 'issue_created',
              startEventLabel: null,
              stopEvent: 'issue_stage_end',
              stopEventLabel: null,
            },
          });
        });

        afterEach(() => {
          wrapper.destroy();
        });

        it('will notify if the current start and stop event pair is not valid', done => {
          expect(wrapper.find(sel.invalidFeedback).exists()).toEqual(false);

          selectDropdownOption(wrapper, sel.startEvent, 2);

          Vue.nextTick(() => {
            expect(wrapper.find(sel.invalidFeedback).exists()).toEqual(true);
            expect(wrapper.find(sel.invalidFeedback).text()).toContain(
              'Start event changed, please select a valid stop event',
            );
            done();
          });
        });

        it('will update the list of stop events', done => {
          const se = wrapper.vm.stopEventOptions;
          selectDropdownOption(wrapper, sel.startEvent, 2);
          Vue.nextTick(() => {
            expect(se[1].value).not.toEqual(wrapper.vm.stopEventOptions[1].value);
            done();
          });
        });

        it('will disable the submit button until a valid stopEvent is selected', done => {
          selectDropdownOption(wrapper, sel.startEvent, 2);
          Vue.nextTick(() => {
            expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
            done();
          });
        });
      });

      describe('Stop event label', () => {
        beforeEach(() => {
          wrapper = createComponent({}, false);
        });

        afterEach(() => {
          wrapper.destroy();
        });

        it('is hidden by default', () => {
          expect(wrapper.find(sel.startEventLabel).exists()).toEqual(false);
        });

        it('will display the stop event label field if a label event is selected', done => {
          expect(wrapper.find(sel.stopEventLabel).exists()).toEqual(false);

          wrapper.setData({
            fields: {
              stopEvent: labelStopEvent.identifier,
              startEvent: labelStartEvent.identifier,
            },
          });

          Vue.nextTick(() => {
            expect(wrapper.find(sel.stopEventLabel).exists()).toEqual(true);
            done();
          });
        });

        it('will set the "stopEventLabel" field when selected', done => {
          const selectedLabelId = groupLabels[1].id;
          expect(wrapper.vm.fields.stopEventLabel).toEqual(null);

          wrapper.setData({
            fields: {
              startEvent: labelStartEvent.identifier,
              stopEvent: labelStopEvent.identifier,
            },
          });

          Vue.nextTick(() => {
            wrapper
              .find(sel.stopEventLabel)
              .findAll('.dropdown-item')
              .at(2) // item at index 0 is 'select a label'
              .trigger('click');

            Vue.nextTick(() => {
              expect(wrapper.vm.fields.stopEventLabel).toEqual(selectedLabelId);
              done();
            });
          });
        });
      });
    });

    describe('Add stage button', () => {
      beforeEach(() => {
        wrapper = createComponent({}, false);

        selectDropdownOption(wrapper, sel.startEvent, 1);

        return Vue.nextTick(() => {
          selectDropdownOption(wrapper, sel.stopEvent, 1);
        });
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('is enabled when all required fields are filled', done => {
        const btn = wrapper.find(sel.submit);

        expect(btn.attributes('disabled')).toEqual('disabled');
        wrapper.find(sel.name).setValue('Cool stage');

        Vue.nextTick(() => {
          expect(btn.attributes('disabled')).toBeUndefined();
          done();
        });
      });

      describe('with all fields set', () => {
        const startEventIndex = 2;
        const stopEventIndex = 1;

        beforeEach(() => {
          wrapper = createComponent({}, false);

          selectDropdownOption(wrapper, sel.startEvent, startEventIndex);

          return Vue.nextTick(() => {
            selectDropdownOption(wrapper, sel.stopEvent, stopEventIndex);
            wrapper.find(sel.name).setValue('Cool stage');
          });
        });

        afterEach(() => {
          wrapper.destroy();
        });

        it('emits a `submit` event when clicked', () => {
          expect(wrapper.emitted().submit).toBeUndefined();

          wrapper.find(sel.submit).trigger('click');
          expect(wrapper.emitted().submit).toBeTruthy();
          expect(wrapper.emitted().submit.length).toEqual(1);
        });

        it('`submit` event receives the latest data', () => {
          expect(wrapper.emitted().submit).toBeUndefined();
          const startEv = startEvents[startEventIndex];
          const selectedStopEvent = getDropdownOption(wrapper, sel.stopEvent, stopEventIndex);

          const res = [
            {
              name: 'Cool stage',
              start_event_identifier: startEv.identifier,
              start_event_label_id: null,
              end_event_identifier: selectedStopEvent.attributes('value'),
              end_event_label_id: null,
            },
          ];

          wrapper.find(sel.submit).trigger('click');
          expect(wrapper.emitted().submit[0]).toEqual(res);
        });
      });
    });

    describe('Cancel button', () => {
      beforeEach(() => {
        wrapper = createComponent({}, false);
      });

      afterEach(() => {
        wrapper.destroy();
      });

      it('is enabled when the form is dirty', done => {
        const btn = wrapper.find(sel.cancel);

        expect(btn.attributes('disabled')).toEqual('disabled');
        wrapper.find(sel.name).setValue('Cool stage');

        Vue.nextTick(() => {
          expect(btn.attributes('disabled')).toBeUndefined();
          done();
        });
      });

      it('will reset the fields when clicked', done => {
        wrapper.setData({
          fields: {
            name: 'Cool stage pre',
            startEvent: labelStartEvent.identifier,
            stopEvent: labelStopEvent.identifier,
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.cancel).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.vm.fields).toEqual({
              name: '',
              startEvent: '',
              startEventLabel: null,
              stopEvent: '',
              stopEventLabel: null,
            });
            done();
          });
        });
      });

      it('will emit the `cancel` event when clicked', done => {
        expect(wrapper.emitted().cancel).toBeUndefined();

        wrapper.setData({
          fields: {
            name: 'Cool stage pre',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.cancel).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.emitted().cancel).toBeTruthy();
            expect(wrapper.emitted().cancel.length).toEqual(1);
            done();
          });
        });
      });
    });
  });

  describe('Prepopulated form', () => {
    beforeEach(() => {
      wrapper = createComponent(
        {
          initialFields: {
            ...initData,
          },
        },
        false,
      );

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
      it('will reset the fields to initial state when clicked', done => {
        wrapper.setData({
          fields: {
            name: 'Cool stage pre',
            startEvent: labelStartEvent.identifier,
            stopEvent: labelStopEvent.identifier,
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.cancel).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.vm.fields).toEqual({
              ...initData,
            });
            done();
          });
        });
      });
    });

    describe('Add stage button', () => {
      it('is disabled by default', () => {
        expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
      });

      it('is enabled when a field is changed and fields are valid', done => {
        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        Vue.nextTick(() => {
          expect(wrapper.find(sel.submit).attributes('disabled')).toBeUndefined();
          done();
        });
      });

      it('is disabled when a field is changed but fields are incomplete', done => {
        wrapper.setData({
          fields: {
            name: '',
          },
        });

        Vue.nextTick(() => {
          expect(wrapper.find(sel.submit).attributes('disabled')).toEqual('disabled');
          done();
        });
      });

      it('emits a `submit` event when clicked', done => {
        expect(wrapper.emitted().submit).toBeUndefined();

        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.submit).trigger('click');

          Vue.nextTick(() => {
            expect(wrapper.emitted().submit).toBeTruthy();
            expect(wrapper.emitted().submit.length).toEqual(1);
            done();
          });
        });
      });

      it('`submit` event receives the latest data', done => {
        wrapper.setData({
          fields: {
            name: 'Cool updated form',
          },
        });

        Vue.nextTick(() => {
          wrapper.find(sel.submit).trigger('click');

          Vue.nextTick(() => {
            const submitted = wrapper.emitted().submit[0];
            expect(submitted).not.toEqual([initData]);
            expect(submitted).toEqual([
              {
                start_event_identifier: labelStartEvent.identifier,
                start_event_label_id: groupLabels[0].id,
                end_event_identifier: labelStopEvent.identifier,
                end_event_label_id: groupLabels[1].id,
                name: 'Cool updated form',
              },
            ]);
            done();
          });
        });
      });
    });
  });

  it('does not have a loading icon', () => {
    expect(wrapper.find(sel.submit).html()).toMatchSnapshot();
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
});
