import Vuex from 'vuex';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import { GlModal } from '@gitlab/ui';
import store from 'ee/analytics/cycle_analytics/store';
import ValueStreamSelect from 'ee/analytics/cycle_analytics/components/value_stream_select.vue';

const localVue = createLocalVue();
localVue.use(Vuex);

describe('ValueStreamSelect', () => {
  let wrapper = null;

  const createValueStreamMock = jest.fn(() => Promise.resolve());
  const mockEvent = { preventDefault: jest.fn() };
  const mockModalHide = jest.fn();
  const mockToastShow = jest.fn();

  const createComponent = ({ data = {}, methods = {} } = {}) =>
    shallowMount(ValueStreamSelect, {
      localVue,
      store,
      data() {
        return {
          ...data,
        };
      },
      methods: {
        createValueStream: createValueStreamMock,
        ...methods,
      },
      mocks: {
        $toast: {
          show: mockToastShow,
        },
      },
    });

  const findModal = () => wrapper.find(GlModal);
  const submitButtonDisabledState = () => findModal().props('actionPrimary').attributes[1].disabled;
  const submitForm = () => findModal().vm.$emit('primary', mockEvent);

  beforeEach(() => {
    wrapper = createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
  });

  describe('Create value stream form', () => {
    it('submit button is disabled', () => {
      expect(submitButtonDisabledState()).toBe(true);
    });

    describe('with valid fields', () => {
      const streamName = 'Cool stream';

      beforeEach(() => {
        wrapper = createComponent({ data: { name: streamName } });
        wrapper.vm.$refs.modal.hide = mockModalHide;
      });

      it('submit button is enabled', () => {
        expect(submitButtonDisabledState()).toBe(false);
      });

      describe('form submitted successfully', () => {
        beforeEach(() => {
          submitForm();
        });
        it('calls the "createValueStream" event when submitted', () => {
          expect(createValueStreamMock).toHaveBeenCalledWith({ name: streamName });
        });

        it('clears the name field', () => {
          expect(wrapper.vm.name).toEqual('');
        });

        it('displays a toast message', () => {
          expect(mockToastShow).toHaveBeenCalledWith(`'${streamName}' Value Stream created`, {
            position: 'top-center',
          });
        });

        it('hides the modal', () => {
          expect(mockModalHide).toHaveBeenCalled();
        });
      });

      describe('form submission fails', () => {
        const createValueStreamMockFail = jest.fn(() => Promise.reject());

        beforeEach(() => {
          wrapper = createComponent({
            data: { name: streamName },
            methods: {
              createValueStream: createValueStreamMockFail,
            },
          });
          wrapper.vm.$refs.modal.hide = mockModalHide;
        });

        it('does not clear the name field', () => {
          expect(wrapper.vm.name).toEqual(streamName);
        });

        it('does not display a toast message', () => {
          expect(mockToastShow).not.toHaveBeenCalled();
        });

        it('does not hide the modal', () => {
          expect(mockModalHide).not.toHaveBeenCalled();
        });
      });
    });
  });
});
