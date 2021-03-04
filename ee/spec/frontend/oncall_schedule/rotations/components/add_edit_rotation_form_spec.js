import { GlDropdownItem, GlTokenSelector, GlFormGroup, GlToggle } from '@gitlab/ui';
import { shallowMount } from '@vue/test-utils';
import AddEditRotationForm from 'ee/oncall_schedules/components/rotations/components/add_edit_rotation_form.vue';
import { LENGTH_ENUM } from 'ee/oncall_schedules/constants';
import waitForPromises from 'helpers/wait_for_promises';
import { participants, getOncallSchedulesQueryResponse } from '../../mocks/apollo_mock';

const projectPath = 'group/project';
const schedule =
  getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];

describe('AddEditRotationForm', () => {
  let wrapper;

  const createComponent = ({ data = {}, props = {} } = {}) => {
    wrapper = shallowMount(AddEditRotationForm, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        ...props,
        schedule,
        isLoading: false,
        validationState: {
          name: true,
          participants: false,
          startsAt: false,
        },
        participants,
        form: {
          name: '',
          participants: [],
          rotationLength: {
            length: 1,
            unit: LENGTH_ENUM.hours,
          },
          startsAt: {
            date: null,
            time: 0,
          },
          endsAt: {
            date: null,
            time: 0,
          },
          restrictedTo: {
            from: 0,
            to: 0,
          },
        },
      },
      provide: {
        projectPath,
      },
    });
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    if (wrapper) {
      wrapper.destroy();
    }
  });

  const findRotationLength = () => wrapper.find('[id="rotation-length"]');
  const findRotationStartTime = () => wrapper.find('[data-testid="rotation-start-time"]');
  const findRotationEndsContainer = () => wrapper.find('[data-testid="rotation-ends-on"]');
  const findEndDateToggle = () => wrapper.find(GlToggle);
  const findRotationEndTime = () => wrapper.find('[data-testid="rotation-end-time"]');
  const findUserSelector = () => wrapper.find(GlTokenSelector);
  const findRotationFormGroups = () => wrapper.findAllComponents(GlFormGroup);
  const findStartsOnTimeOptions = () => findRotationStartTime().findAllComponents(GlDropdownItem);
  const findEndsOnTimeOptions = () => findRotationEndTime().findAllComponents(GlDropdownItem);
  const findRestrictedToTime = () => wrapper.find('[data-testid="restricted-to-time"]');
  const findRestrictedToToggle = () => wrapper.find('[data-testid="restricted-to-toggle"]');
  const findRestrictedFromOptions = () =>
    wrapper.find('[data-testid="restricted-from"]').findAllComponents(GlDropdownItem);
  const findRestrictedToOptions = () =>
    wrapper.find('[data-testid="restricted-to"]').findAllComponents(GlDropdownItem);

  describe('Rotation form validation', () => {
    it.each`
      index | type              | validationState | value
      ${0}  | ${'name'}         | ${true}         | ${'true'}
      ${1}  | ${'participants'} | ${false}        | ${undefined}
      ${3}  | ${'startsAt'}     | ${false}        | ${undefined}
    `(
      'form validation for $type returns $value when passed validate state of $validationState',
      ({ index, value }) => {
        const formGroup = findRotationFormGroups();
        expect(formGroup.at(index).attributes('state')).toBe(value);
      },
    );
  });

  describe('Rotation length and start time', () => {
    it('renders the rotation length value', async () => {
      const rotationLength = findRotationLength();
      expect(rotationLength.exists()).toBe(true);
      expect(rotationLength.attributes('value')).toBe('1');
    });

    it('renders the rotation starts on datepicker', async () => {
      const startsOn = findRotationStartTime();
      expect(startsOn.exists()).toBe(true);
      expect(startsOn.attributes('text')).toBe('00:00');
      expect(startsOn.attributes('headertext')).toBe('');
    });

    it('should emit an event with selected value on time selection', async () => {
      const option = 3;
      findStartsOnTimeOptions().at(option).vm.$emit('click');
      await wrapper.vm.$nextTick();
      const emittedEvent = wrapper.emitted('update-rotation-form');
      expect(emittedEvent).toHaveLength(1);
      expect(emittedEvent[0][0]).toEqual({ type: 'startsAt.time', value: option });
    });

    it('should add a checkmark to a selected start time', async () => {
      const time = 7;
      wrapper.setProps({
        form: {
          startsAt: {
            time,
          },
          rotationLength: {
            length: 1,
            unit: LENGTH_ENUM.hours,
          },
        },
      });
      await wrapper.vm.$nextTick();
      expect(findStartsOnTimeOptions().at(time).props('isChecked')).toBe(true);
    });
  });

  describe('Rotation end time', () => {
    it('toggles end time visibility', async () => {
      const toggle = findEndDateToggle().vm;
      toggle.$emit('change', false);
      await wrapper.vm.$nextTick();
      expect(findRotationEndsContainer().exists()).toBe(false);
      toggle.$emit('change', true);
      await wrapper.vm.$nextTick();
      expect(findRotationEndsContainer().exists()).toBe(true);
    });

    it('should emit an event with selected value on time selection', async () => {
      findEndDateToggle().vm.$emit('change', true);
      await wrapper.vm.$nextTick();
      const option = 3;
      findEndsOnTimeOptions().at(option).vm.$emit('click');
      await wrapper.vm.$nextTick();
      const emittedEvent = wrapper.emitted('update-rotation-form');
      expect(emittedEvent).toHaveLength(1);
      expect(emittedEvent[0][0]).toEqual({ type: 'endsAt.time', value: option });
    });

    it('should add a checkmark to a selected end time', async () => {
      findEndDateToggle().vm.$emit('change', true);
      const time = 5;
      wrapper.setProps({
        form: {
          endsAt: {
            time,
          },
          startsAt: {
            time: 0,
          },
          rotationLength: {
            length: 1,
            unit: LENGTH_ENUM.hours,
          },
        },
      });
      await wrapper.vm.$nextTick();
      expect(findEndsOnTimeOptions().at(time).props('isChecked')).toBe(true);
    });
  });

  describe('Rotation restricted to time', () => {
    it('toggles restricted to time visibility', async () => {
      const toggle = findRestrictedToToggle().vm;
      toggle.$emit('change', false);
      await wrapper.vm.$nextTick();
      expect(findRestrictedToTime().exists()).toBe(false);
      toggle.$emit('change', true);
      await wrapper.vm.$nextTick();
      expect(findRestrictedToTime().exists()).toBe(true);
    });

    it('should emit an event with selected value on restricted FROM time selection', async () => {
      findRestrictedToToggle().vm.$emit('change', true);
      await wrapper.vm.$nextTick();
      const timeFrom = 5;
      const timeTo = 22;
      findRestrictedFromOptions().at(timeFrom).vm.$emit('click');
      findRestrictedToOptions().at(timeTo).vm.$emit('click');
      await wrapper.vm.$nextTick();
      const emittedEvent = wrapper.emitted('update-rotation-form');
      expect(emittedEvent).toHaveLength(2);
      expect(emittedEvent[0][0]).toEqual({ type: 'restrictedTo.from', value: timeFrom + 1 });
      expect(emittedEvent[1][0]).toEqual({ type: 'restrictedTo.to', value: timeTo + 1 });
    });

    it('should add a checkmark to a selected  restricted FROM time', async () => {
      findRestrictedToToggle().vm.$emit('change', true);
      const timeFrom = 5;
      const timeTo = 22;

      wrapper.setProps({
        form: {
          endsAt: {
            time: 0,
          },
          startsAt: {
            time: 0,
          },
          restrictedTo: {
            from: timeFrom,
            to: timeTo,
          },
          rotationLength: {
            length: 1,
            unit: LENGTH_ENUM.hours,
          },
        },
      });
      await wrapper.vm.$nextTick();
      expect(
        findRestrictedFromOptions()
          .at(timeFrom - 1)
          .props('isChecked'),
      ).toBe(true);
      expect(
        findRestrictedToOptions()
          .at(timeTo - 1)
          .props('isChecked'),
      ).toBe(true);
    });
  });

  describe('filter participants', () => {
    beforeEach(() => {
      createComponent();
    });

    it('has user options that are populated via apollo', () => {
      expect(findUserSelector().props('dropdownItems')).toHaveLength(participants.length);
    });

    it('calls the API and sets dropdown items as request result', async () => {
      const tokenSelector = findUserSelector();

      tokenSelector.vm.$emit('focus');
      tokenSelector.vm.$emit('blur');
      tokenSelector.vm.$emit('focus');

      await waitForPromises();

      expect(tokenSelector.props('dropdownItems')).toMatchObject(participants);
      expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
    });

    it('emits `input` event with selected users', () => {
      findUserSelector().vm.$emit('input', participants);

      expect(findUserSelector().emitted().input[0][0]).toEqual(participants);
    });

    it('when text input is blurred the text input clears', async () => {
      const tokenSelector = findUserSelector();
      tokenSelector.vm.$emit('blur');

      await wrapper.vm.$nextTick();

      expect(tokenSelector.props('hideDropdownWithNoItems')).toBe(false);
    });
  });
});
