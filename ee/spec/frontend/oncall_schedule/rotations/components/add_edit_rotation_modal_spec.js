import { GlModal, GlAlert } from '@gitlab/ui';
import { shallowMount, createLocalVue } from '@vue/test-utils';
import VueApollo from 'vue-apollo';
import AddEditRotationForm from 'ee/oncall_schedules/components/rotations/components/add_edit_rotation_form.vue';
import AddEditRotationModal, {
  i18n,
} from 'ee/oncall_schedules/components/rotations/components/add_edit_rotation_modal.vue';
import { addRotationModalId } from 'ee/oncall_schedules/constants';
import createOncallScheduleRotationMutation from 'ee/oncall_schedules/graphql/mutations/create_oncall_schedule_rotation.mutation.graphql';
import getOncallSchedulesWithRotationsQuery from 'ee/oncall_schedules/graphql/queries/get_oncall_schedules.query.graphql';
import createMockApollo from 'helpers/mock_apollo_helper';
import waitForPromises from 'helpers/wait_for_promises';
import createFlash, { FLASH_TYPES } from '~/flash';
import searchProjectMembersQuery from '~/graphql_shared/queries/project_user_members_search.query.graphql';
import {
  participants,
  getOncallSchedulesQueryResponse,
  createRotationResponse,
  createRotationResponseWithErrors,
} from '../../mocks/apollo_mock';

jest.mock('~/flash');

const schedule =
  getOncallSchedulesQueryResponse.data.project.incidentManagementOncallSchedules.nodes[0];
const localVue = createLocalVue();
const projectPath = 'group/project';
const mutate = jest.fn();
const mockHideModal = jest.fn();

describe('AddEditRotationModal', () => {
  let wrapper;
  let fakeApollo;
  let userSearchQueryHandler;
  let createRotationHandler;

  async function awaitApolloDomMock() {
    await wrapper.vm.$nextTick(); // kick off the DOM update
    await jest.runOnlyPendingTimers(); // kick off the mocked GQL stuff (promises)
    await wrapper.vm.$nextTick(); // kick off the DOM update for flash
  }

  async function createRotation(localWrapper) {
    localWrapper.find(GlModal).vm.$emit('primary', { preventDefault: jest.fn() });
  }

  const createComponent = ({ data = {}, props = {}, loading = false } = {}) => {
    wrapper = shallowMount(AddEditRotationModal, {
      data() {
        return {
          ...data,
        };
      },
      propsData: {
        modalId: addRotationModalId,
        schedule,
        ...props,
      },
      provide: {
        projectPath,
      },
      mocks: {
        $apollo: {
          queries: {
            participants: {
              loading,
            },
          },
          mutate,
        },
      },
    });
    wrapper.vm.$refs.addEditScheduleRotationModal.hide = mockHideModal;
  };

  const createComponentWithApollo = ({
    search = '',
    createHandler = jest.fn().mockResolvedValue(createRotationResponse),
  } = {}) => {
    createRotationHandler = createHandler;
    localVue.use(VueApollo);

    fakeApollo = createMockApollo([
      [
        getOncallSchedulesWithRotationsQuery,
        jest.fn().mockResolvedValue(getOncallSchedulesQueryResponse),
      ],
      [searchProjectMembersQuery, userSearchQueryHandler],
      [createOncallScheduleRotationMutation, createRotationHandler],
    ]);

    fakeApollo.clients.defaultClient.cache.writeQuery({
      query: getOncallSchedulesWithRotationsQuery,
      variables: {
        projectPath: 'group/project',
      },
      data: getOncallSchedulesQueryResponse.data,
    });

    wrapper = shallowMount(AddEditRotationModal, {
      localVue,
      propsData: {
        modalId: addRotationModalId,
        schedule,
      },
      apolloProvider: fakeApollo,
      data() {
        return {
          ptSearchTerm: search,
          form: {
            participants,
          },
          participants,
        };
      },
      provide: {
        projectPath,
      },
    });

    wrapper.vm.$refs.addEditScheduleRotationModal.hide = mockHideModal;
  };

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findModal = () => wrapper.findComponent(GlModal);
  const findAlert = () => wrapper.findComponent(GlAlert);
  const findForm = () => wrapper.findComponent(AddEditRotationForm);

  it('renders rotation modal layout', () => {
    expect(wrapper.element).toMatchSnapshot();
  });

  describe('Rotation create', () => {
    it('makes a request with `oncallRotationCreate` to create a schedule rotation', () => {
      mutate.mockResolvedValueOnce({});
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      expect(mutate).toHaveBeenCalledWith({
        mutation: expect.any(Object),
        variables: { input: expect.objectContaining({ projectPath }) },
      });
    });

    it('does not hide the rotation modal and shows error alert on fail', async () => {
      const error = 'some error';
      mutate.mockResolvedValueOnce({ data: { oncallRotationCreate: { errors: [error] } } });
      findModal().vm.$emit('primary', { preventDefault: jest.fn() });
      await waitForPromises();
      expect(mockHideModal).not.toHaveBeenCalled();
      expect(findAlert().exists()).toBe(true);
      expect(findAlert().text()).toContain(error);
    });

    describe('Validation', () => {
      describe('name', () => {
        it('is valid when name is NOT empty', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', { type: 'name', value: '' });
          expect(form.props('validationState').name).toBe(false);
        });

        it('is NOT valid when name is empty', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', { type: 'name', value: 'Some value' });
          expect(form.props('validationState').name).toBe(true);
        });
      });

      describe('participants', () => {
        it('is valid when participants array is NOT empty', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', {
            type: 'participants',
            value: ['user1', 'user2'],
          });
          expect(form.props('validationState').participants).toBe(true);
        });

        it('is NOT valid when participants array is empty', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', { type: 'participants', value: [] });
          expect(form.props('validationState').participants).toBe(false);
        });
      });

      describe('startsAt date', () => {
        it('is valid when date is NOT empty', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', {
            type: 'startsAt.date',
            value: new Date('10/12/2021'),
          });
          expect(form.props('validationState').startsAt).toBe(true);
        });

        it('is NOT valid when date is empty', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', { type: 'startsAt.time', value: null });
          expect(form.props('validationState').startsAt).toBe(false);
        });
      });

      describe('endsAt date', () => {
        it('is valid when date is empty', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', { type: 'endsAt.date', value: null });
          expect(form.props('validationState').endsAt).toBe(true);
        });

        it('is valid when start date is smaller then end date', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', {
            type: 'startsAt.date',
            value: new Date('9/11/2021'),
          });
          form.vm.$emit('update-rotation-form', {
            type: 'endsAt.date',
            value: new Date('10/11/2021'),
          });
          expect(form.props('validationState').endsAt).toBe(true);
        });

        it('is invalid when start date is larger then end date', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', {
            type: 'startsAt.date',
            value: new Date('11/11/2021'),
          });
          form.vm.$emit('update-rotation-form', {
            type: 'endsAt.date',
            value: new Date('10/11/2021'),
          });
          expect(form.props('validationState').endsAt).toBe(false);
        });

        it('is valid when start and end dates are equal but time is smaller on start date', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', {
            type: 'startsAt.date',
            value: new Date('11/11/2021'),
          });
          form.vm.$emit('update-rotation-form', { type: 'startsAt.time', value: 10 });
          form.vm.$emit('update-rotation-form', {
            type: 'endsAt.date',
            value: new Date('11/11/2021'),
          });
          form.vm.$emit('update-rotation-form', { type: 'endsAt.time', value: 22 });
          expect(form.props('validationState').endsAt).toBe(true);
        });

        it('is invalid when start and end dates are equal but time is larger on start date', () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', {
            type: 'startsAt.date',
            value: new Date('11/11/2021'),
          });
          form.vm.$emit('update-rotation-form', { type: 'startsAt.time', value: 10 });
          form.vm.$emit('update-rotation-form', {
            type: 'endsAt.date',
            value: new Date('11/11/2021'),
          });
          form.vm.$emit('update-rotation-form', { type: 'endsAt.time', value: 8 });
          expect(form.props('validationState').endsAt).toBe(false);
        });
      });

      describe('Toggle primary button state', () => {
        it('should disable primary button when any of the fields is invalid', async () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', { type: 'name', value: 'lalal' });
          await wrapper.vm.$nextTick();
          expect(findModal().props('actionPrimary').attributes).toEqual(
            expect.arrayContaining([{ disabled: true }]),
          );
        });

        it('should enable primary button when all fields are valid', async () => {
          const form = findForm();
          form.vm.$emit('update-rotation-form', { type: 'name', value: 'Value' });
          form.vm.$emit('update-rotation-form', { type: 'participants', value: [1, 2, 3] });
          form.vm.$emit('update-rotation-form', {
            type: 'startsAt.date',
            value: new Date('11/10/2021'),
          });
          form.vm.$emit('update-rotation-form', {
            type: 'endsAt.date',
            value: new Date('12/10/2021'),
          });
          await wrapper.vm.$nextTick();
          expect(findModal().props('actionPrimary').attributes).toEqual(
            expect.arrayContaining([{ disabled: false }]),
          );
        });
      });
    });
  });

  describe('with mocked Apollo client', () => {
    it('it calls the `searchProjectMembersQuery` query with the search parameter and project path', async () => {
      userSearchQueryHandler = jest.fn().mockResolvedValue({
        data: {
          users: {
            nodes: participants,
          },
        },
      });
      createComponentWithApollo({ search: 'root' });
      await awaitApolloDomMock();
      expect(userSearchQueryHandler).toHaveBeenCalledWith({
        search: 'root',
        fullPath: projectPath,
      });
    });

    it('calls a mutation with correct parameters and creates a rotation', async () => {
      createComponentWithApollo();
      expect(wrapper.emitted('fetchRotationShifts')).toBeUndefined();

      await createRotation(wrapper);
      await awaitApolloDomMock();

      expect(mockHideModal).toHaveBeenCalled();
      expect(createRotationHandler).toHaveBeenCalled();
      expect(createFlash).toHaveBeenCalledWith({
        message: i18n.rotationCreated,
        type: FLASH_TYPES.SUCCESS,
      });
      expect(wrapper.emitted('fetchRotationShifts')).toHaveLength(1);
    });

    it('displays alert if mutation had a recoverable error', async () => {
      createComponentWithApollo({
        createHandler: jest.fn().mockResolvedValue(createRotationResponseWithErrors),
      });

      await createRotation(wrapper);
      await awaitApolloDomMock();

      const alert = findAlert();
      expect(alert.exists()).toBe(true);
      expect(alert.text()).toContain('Houston, we have a problem');
    });
  });
});
