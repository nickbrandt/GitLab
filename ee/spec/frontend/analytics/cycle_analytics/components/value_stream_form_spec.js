import { GlModal, GlFormInput } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import Vuex from 'vuex';
import { PRESET_OPTIONS_BLANK } from 'ee/analytics/cycle_analytics/components/create_value_stream_form/constants';
import CustomStageFields from 'ee/analytics/cycle_analytics/components/create_value_stream_form/custom_stage_fields.vue';
import DefaultStageFields from 'ee/analytics/cycle_analytics/components/create_value_stream_form/default_stage_fields.vue';
import ValueStreamForm from 'ee/analytics/cycle_analytics/components/value_stream_form.vue';
import { mockTracking, unmockTracking } from 'helpers/tracking_helper';
import { extendedWrapper } from 'helpers/vue_test_utils_helper';
import {
  convertObjectPropsToCamelCase,
  convertObjectPropsToSnakeCase,
} from '~/lib/utils/common_utils';
import { customStageEvents as formEvents, defaultStageConfig, rawCustomStage } from '../mock_data';

const scrollIntoViewMock = jest.fn();
HTMLElement.prototype.scrollIntoView = scrollIntoViewMock;

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ValueStreamForm', () => {
  let wrapper = null;
  let trackingSpy = null;

  const createValueStreamMock = jest.fn(() => Promise.resolve());
  const updateValueStreamMock = jest.fn(() => Promise.resolve());
  const mockEvent = { preventDefault: jest.fn() };
  const mockToastShow = jest.fn();
  const streamName = 'Cool stream';
  const initialFormErrors = { name: ['Name field required'] };
  const initialFormStageErrors = {
    stages: [
      {
        name: ['Name field is required'],
        endEventIdentifier: ['Please select a start event first'],
      },
    ],
  };

  const initialData = {
    stages: [convertObjectPropsToCamelCase(rawCustomStage)],
    id: 1337,
    name: 'Editable value stream',
  };

  const initialPreset = PRESET_OPTIONS_BLANK;

  const fakeStore = () =>
    new Vuex.Store({
      state: {
        isCreatingValueStream: false,
        formEvents,
      },
      actions: {
        createValueStream: createValueStreamMock,
        updateValueStream: updateValueStreamMock,
      },
    });

  const createComponent = ({ props = {}, data = {}, stubs = {} } = {}) =>
    extendedWrapper(
      shallowMount(ValueStreamForm, {
        localVue,
        store: fakeStore(),
        data() {
          return {
            ...data,
          };
        },
        propsData: {
          defaultStageConfig,
          ...props,
        },
        mocks: {
          $toast: {
            show: mockToastShow,
          },
        },
        stubs: {
          ...stubs,
        },
      }),
    );

  const findModal = () => wrapper.findComponent(GlModal);
  const findExtendedFormFields = () => wrapper.findByTestId('extended-form-fields');
  const findPresetSelector = () => wrapper.findByTestId('vsa-preset-selector');
  const findRestoreButton = (index) => wrapper.findByTestId(`stage-action-restore-${index}`);
  const findHiddenStages = () => wrapper.findAllByTestId('vsa-hidden-stage').wrappers;
  const findBtn = (btn) => findModal().props(btn);

  const clickSubmit = () => findModal().vm.$emit('primary', mockEvent);
  const clickAddStage = () => findModal().vm.$emit('secondary', mockEvent);
  const clickRestoreStageAtIndex = (index) => findRestoreButton(index).vm.$emit('click');
  const expectFieldError = (testId, error = '') =>
    expect(wrapper.findByTestId(testId).attributes('invalid-feedback')).toBe(error);

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  describe('default state', () => {
    beforeEach(() => {
      wrapper = createComponent();
    });

    it('has the extended fields', () => {
      expect(findExtendedFormFields().exists()).toBe(true);
    });

    it('sets the submit action text to "Create Value Stream"', () => {
      expect(findBtn('actionPrimary').text).toBe('Create Value Stream');
    });

    describe('Preset selector', () => {
      it('has the preset button', () => {
        expect(findPresetSelector().exists()).toBe(true);
      });
    });

    it('does not display any hidden stages', () => {
      expect(findHiddenStages().length).toBe(0);
    });

    describe('Add stage button', () => {
      beforeEach(() => {
        wrapper = createComponent({
          stubs: {
            CustomStageFields,
          },
        });
      });

      it('has the add stage button', () => {
        expect(findBtn('actionSecondary')).toMatchObject({ text: 'Add another stage' });
      });

      it('adds a blank custom stage when clicked', async () => {
        expect(wrapper.vm.stages).toHaveLength(defaultStageConfig.length);

        await clickAddStage();

        expect(wrapper.vm.stages.length).toBe(defaultStageConfig.length + 1);
      });

      it('validates existing fields when clicked', async () => {
        expect(wrapper.vm.nameError).toHaveLength(0);

        await clickAddStage();

        expect(wrapper.vm.nameError).toEqual(['Name is required']);
      });
    });

    describe('form errors', () => {
      const commonExtendedData = {
        props: {
          initialFormErrors: initialFormStageErrors,
        },
      };

      it('renders errors for a default stage field', () => {
        wrapper = createComponent({
          ...commonExtendedData,
          stubs: {
            DefaultStageFields,
          },
        });

        expectFieldError('default-stage-name-0', initialFormStageErrors.stages[0].name[0]);
      });

      it('renders errors for a custom stage field', async () => {
        wrapper = createComponent({
          props: {
            ...commonExtendedData.props,
            initialPreset: PRESET_OPTIONS_BLANK,
          },
          stubs: {
            CustomStageFields,
          },
        });

        expectFieldError('custom-stage-name-0', initialFormStageErrors.stages[0].name[0]);
        expectFieldError(
          'custom-stage-end-event-0',
          initialFormStageErrors.stages[0].endEventIdentifier[0],
        );
      });
    });

    describe('isEditing=true', () => {
      const stageCount = initialData.stages.length;
      beforeEach(() => {
        wrapper = createComponent({
          props: {
            initialPreset,
            initialData,
            isEditing: true,
          },
        });
      });

      it('does not have the preset button', () => {
        expect(findPresetSelector().exists()).toBe(false);
      });

      it('sets the submit action text to "Save Value Stream"', () => {
        expect(findBtn('actionPrimary').text).toBe('Save Value Stream');
      });

      it('does not display any hidden stages', () => {
        expect(findHiddenStages().length).toBe(0);
      });

      describe('with hidden stages', () => {
        const hiddenStages = defaultStageConfig.map((s) => ({ ...s, hidden: true }));

        beforeEach(() => {
          wrapper = createComponent({
            props: {
              initialPreset,
              initialData: { ...initialData, stages: [...initialData.stages, ...hiddenStages] },
              isEditing: true,
            },
          });
        });

        it('displays hidden each stage', () => {
          expect(findHiddenStages().length).toBe(hiddenStages.length);

          findHiddenStages().forEach((s) => {
            expect(s.text()).toContain('Restore stage');
          });
        });

        it('when `Restore stage` is clicked, the stage is restored', async () => {
          await clickRestoreStageAtIndex(1);

          expect(findHiddenStages().length).toBe(hiddenStages.length - 1);
          expect(wrapper.vm.stages.length).toBe(stageCount + 1);
        });
      });

      describe('Add stage button', () => {
        beforeEach(() => {
          wrapper = createComponent({
            props: {
              initialPreset,
              initialData,
              isEditing: true,
            },
            stubs: {
              CustomStageFields,
            },
          });
        });

        it('has the add stage button', () => {
          expect(findBtn('actionSecondary')).toMatchObject({ text: 'Add another stage' });
        });

        it('adds a blank custom stage when clicked', async () => {
          expect(wrapper.vm.stages.length).toBe(stageCount);

          await clickAddStage();

          expect(wrapper.vm.stages.length).toBe(stageCount + 1);
        });

        it('validates existing fields when clicked', async () => {
          expect(wrapper.vm.nameError).toEqual([]);

          wrapper
            .findByTestId('create-value-stream-name')
            .findComponent(GlFormInput)
            .vm.$emit('input', '');
          await clickAddStage();

          expect(wrapper.vm.nameError).toEqual(['Name is required']);
        });
      });

      describe('with valid fields', () => {
        beforeEach(() => {
          trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
          wrapper = createComponent({
            props: {
              initialPreset,
              initialData,
              isEditing: true,
            },
          });
        });

        afterEach(() => {
          unmockTracking();
          wrapper.destroy();
        });

        describe('form submitted successfully', () => {
          beforeEach(() => {
            clickSubmit();
          });

          it('calls the "updateValueStreamMock" event when submitted', () => {
            expect(updateValueStreamMock).toHaveBeenCalledWith(expect.any(Object), {
              ...initialData,
              stages: initialData.stages.map((stage) =>
                convertObjectPropsToSnakeCase(stage, { deep: true }),
              ),
            });
          });

          it('displays a toast message', () => {
            expect(mockToastShow).toHaveBeenCalledWith(`'${initialData.name}' Value Stream saved`);
          });

          it('sends tracking information', () => {
            expect(trackingSpy).toHaveBeenCalledWith(undefined, 'submit_form', {
              label: 'edit_value_stream',
            });
          });
        });

        describe('form submission fails', () => {
          beforeEach(() => {
            wrapper = createComponent({
              data: { name: streamName },
              props: {
                initialFormErrors,
              },
            });

            clickSubmit();
          });

          it('does not call the updateValueStreamMock action', () => {
            expect(updateValueStreamMock).not.toHaveBeenCalled();
          });

          it('does not clear the name field', () => {
            expect(wrapper.vm.name).toBe(streamName);
          });

          it('does not display a toast message', () => {
            expect(mockToastShow).not.toHaveBeenCalled();
          });
        });
      });
    });
  });

  describe('form errors', () => {
    beforeEach(() => {
      wrapper = createComponent({
        data: { name: '' },
        props: {
          initialFormErrors,
        },
      });
    });

    it('renders errors for the name field', () => {
      expectFieldError('create-value-stream-name', initialFormErrors.name[0]);
    });
  });

  describe('with valid fields', () => {
    beforeEach(() => {
      wrapper = createComponent({ data: { name: streamName } });
      trackingSpy = mockTracking(undefined, wrapper.element, jest.spyOn);
    });

    afterEach(() => {
      unmockTracking();
      wrapper.destroy();
    });

    describe('form submitted successfully', () => {
      beforeEach(() => {
        clickSubmit();
      });

      it('calls the "createValueStream" event when submitted', () => {
        expect(createValueStreamMock).toHaveBeenCalledWith(expect.any(Object), {
          name: streamName,
          stages: [
            {
              custom: false,
              name: 'issue',
            },
            {
              custom: false,
              name: 'plan',
            },
            {
              custom: false,
              name: 'code',
            },
          ],
        });
      });

      it('clears the name field', () => {
        expect(wrapper.vm.name).toBe('');
      });

      it('displays a toast message', () => {
        expect(mockToastShow).toHaveBeenCalledWith(`'${streamName}' Value Stream created`);
      });

      it('sends tracking information', () => {
        expect(trackingSpy).toHaveBeenCalledWith(undefined, 'submit_form', {
          label: 'create_value_stream',
        });
      });
    });

    describe('form submission fails', () => {
      beforeEach(() => {
        wrapper = createComponent({
          data: { name: streamName },
          props: {
            initialFormErrors,
          },
        });

        clickSubmit();
      });

      it('calls the createValueStream action', () => {
        expect(createValueStreamMock).toHaveBeenCalled();
      });

      it('does not clear the name field', () => {
        expect(wrapper.vm.name).toBe(streamName);
      });

      it('does not display a toast message', () => {
        expect(mockToastShow).not.toHaveBeenCalled();
      });
    });
  });
});
