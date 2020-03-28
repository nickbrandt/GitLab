import { GlFormRadioGroup, GlLoadingIcon, GlTooltip } from '@gitlab/ui';
import { mount, shallowMount } from '@vue/test-utils';
import Vue from 'vue';
import Status from 'ee/sidebar/components/status/status.vue';
import { healthStatus, healthStatusColorMap, healthStatusTextMap } from 'ee/sidebar/constants';

const getStatusText = wrapper => wrapper.find('.value').text();

const getTooltipText = wrapper => wrapper.find(GlTooltip).text();

const getStatusIconCssClasses = wrapper => wrapper.find('[name="severity-low"]').classes();

const getEditButton = wrapper => wrapper.find({ ref: 'editButton' });

const getEditForm = wrapper => wrapper.find('form');

const getRadioInputs = wrapper => wrapper.findAll('input[type="radio"]');

const getRadioComponent = wrapper => wrapper.find(GlFormRadioGroup);

describe('Status', () => {
  let wrapper;

  function shallowMountStatus(propsData) {
    wrapper = shallowMount(Status, {
      propsData,
    });
  }

  function mountStatus(propsData) {
    wrapper = mount(Status, {
      propsData,
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('shows the text "Status"', () => {
    shallowMountStatus();

    expect(wrapper.find('.title').text()).toBe('Status');
  });

  describe('loading icon', () => {
    it('is displayed when retrieving data', () => {
      const props = {
        isFetching: true,
      };

      shallowMountStatus(props);

      expect(wrapper.contains(GlLoadingIcon)).toBe(true);
    });

    it('is hidden when not retrieving data', () => {
      const props = {
        isFetching: false,
      };

      shallowMountStatus(props);

      expect(wrapper.contains(GlLoadingIcon)).toBe(false);
    });
  });

  describe('edit button', () => {
    it('is displayed when user can edit', () => {
      const props = {
        isEditable: true,
      };

      shallowMountStatus(props);

      expect(getEditButton(wrapper).exists()).toBe(true);
    });

    it('is hidden when user cannot edit', () => {
      const props = {
        isEditable: false,
      };

      shallowMountStatus(props);

      expect(getEditButton(wrapper).exists()).toBe(false);
    });
  });

  describe('status text', () => {
    describe('when no value is provided for status', () => {
      beforeEach(() => {
        const props = {
          status: '',
        };

        shallowMountStatus(props);
      });

      it('shows "None"', () => {
        expect(getStatusText(wrapper)).toBe('None');
      });

      it('shows "Status" in the tooltip', () => {
        expect(getTooltipText(wrapper)).toBe('Status');
      });
    });

    describe.each(Object.values(healthStatus))(`when "%s" is provided for status`, statusValue => {
      beforeEach(() => {
        const props = {
          status: statusValue,
        };

        shallowMountStatus(props);
      });

      it(`shows "${healthStatusTextMap[statusValue]}"`, () => {
        expect(getStatusText(wrapper)).toBe(healthStatusTextMap[statusValue]);
      });

      it(`shows "Status: ${healthStatusTextMap[statusValue]}" in the tooltip`, () => {
        expect(getTooltipText(wrapper)).toBe(`Status: ${healthStatusTextMap[statusValue]}`);
      });

      it(`uses ${healthStatusColorMap[statusValue]} color for the status icon`, () => {
        expect(getStatusIconCssClasses(wrapper)).toContain(healthStatusColorMap[statusValue]);
      });
    });
  });

  describe('status edit form', () => {
    it('is hidden by default', () => {
      const props = {
        isEditable: true,
      };

      shallowMountStatus(props);

      expect(getEditForm(wrapper).exists()).toBe(false);
    });

    describe('when hidden', () => {
      beforeEach(() => {
        const props = {
          isEditable: true,
        };

        shallowMountStatus(props);
      });

      it('shows the form when the Edit button is clicked', () => {
        getEditButton(wrapper).trigger('click');

        return Vue.nextTick().then(() => {
          expect(getEditForm(wrapper).exists()).toBe(true);
        });
      });
    });

    describe('when visible', () => {
      beforeEach(() => {
        const props = {
          isEditable: true,
        };

        shallowMountStatus(props);

        wrapper.setData({ isFormShowing: true });
      });

      it('shows text to ask the user to pick an option', () => {
        const message =
          'Choose which status most accurately reflects the current state of this issue:';
        expect(
          getEditForm(wrapper)
            .find('p')
            .text(),
        ).toContain(message);
      });

      it('hides form when the Edit button is clicked', () => {
        getEditButton(wrapper).trigger('click');

        return Vue.nextTick().then(() => {
          expect(getEditForm(wrapper).exists()).toBe(false);
        });
      });

      it('hides form when the Cancel button is clicked', () => {
        const button = getEditForm(wrapper).find('[type="button"]');

        button.vm.$emit('click');

        return Vue.nextTick().then(() => {
          expect(getEditForm(wrapper).exists()).toBe(false);
        });
      });

      it('hides form when the form is submitted', () => {
        getEditForm(wrapper).trigger('submit');

        return Vue.nextTick().then(() => {
          expect(getEditForm(wrapper).exists()).toBe(false);
        });
      });
    });

    describe('radio buttons', () => {
      beforeEach(() => {
        const props = {
          isEditable: true,
        };

        mountStatus(props);

        wrapper.setData({ isFormShowing: true });
      });

      it('shows 3 radio buttons', () => {
        expect(getRadioInputs(wrapper).length).toBe(3);
      });

      // Test that "On track", "Needs attention", and "At risk" are displayed
      it.each(Object.values(healthStatusTextMap))('shows "%s" text', statusText => {
        expect(getRadioComponent(wrapper).text()).toContain(statusText);
      });

      // Test that "onTrack", "needsAttention", and "atRisk" values are emitted when form is submitted
      it.each(Object.values(healthStatus))(
        'emits onFormSubmit event with argument "%s" when user selects the option and submits form',
        status => {
          getEditForm(wrapper)
            .find(`input[value="${status}"]`)
            .trigger('click');

          return Vue.nextTick().then(() => {
            getEditForm(wrapper).trigger('submit');
            expect(wrapper.emitted().onFormSubmit[0]).toEqual([status]);
          });
        },
      );
    });
  });
});
