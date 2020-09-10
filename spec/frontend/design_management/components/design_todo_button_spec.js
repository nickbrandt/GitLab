import { shallowMount, mount } from '@vue/test-utils';
import TodoButton from '~/vue_shared/components/todo_button.vue';
import DesignTodoButton from '~/design_management/components/design_todo_button.vue';
import createDesignTodoMutation from '~/design_management/graphql/mutations/create_design_todo.mutation.graphql';
import todoMarkDoneMutation from '~/graphql_shared/mutations/todo_mark_done.mutation.graphql';
import mockDesign from '../mock_data/design';
import * as utils from '~/design_management/utils/design_management_utils';

const mockDesignWithPendingTodos = {
  ...mockDesign,
  currentUserTodos: {
    nodes: [
      {
        id: 'todo-id',
      },
    ],
  },
};

const mutate = jest.fn().mockResolvedValue();

describe('Design management design todo button', () => {
  let wrapper;

  function createComponent(props = {}, { mountFn = shallowMount } = {}) {
    wrapper = mountFn(DesignTodoButton, {
      propsData: {
        design: mockDesign,
        ...props,
      },
      provide: {
        projectPath: 'project-path',
        issueIid: '10',
      },
      mocks: {
        $route: {
          params: {
            id: 'my-design.jpg',
          },
          query: {},
        },
        $apollo: {
          mutate,
        },
      },
    });
  }

  beforeEach(() => {
    createComponent();
  });

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
    jest.clearAllMocks();
  });

  it('renders TodoButton component', () => {
    expect(wrapper.find(TodoButton).exists()).toBe(true);
  });

  describe('when design has a pending todo', () => {
    beforeEach(() => {
      createComponent({ design: mockDesignWithPendingTodos }, { mountFn: mount });
    });

    it('renders correct button text', () => {
      expect(wrapper.text()).toBe('Mark as done');
    });

    describe('when clicked', () => {
      beforeEach(() => {
        utils.dispatchDocumentEvent = jest.fn();
        jest.spyOn(document, 'querySelector').mockReturnValue({
          innerText: 2,
        });

        createComponent({ design: mockDesignWithPendingTodos }, { mountFn: mount });
        wrapper.trigger('click');
        return wrapper.vm.$nextTick();
      });

      it('calls `$apollo.mutate` with the `todoMarkDone` mutation and variables containing `id`', async () => {
        const todoMarkDoneMutationVariables = {
          mutation: todoMarkDoneMutation,
          update: expect.anything(),
          variables: {
            id: 'todo-id',
          },
        };

        expect(mutate).toHaveBeenCalledTimes(1);
        expect(mutate).toHaveBeenCalledWith(todoMarkDoneMutationVariables);
      });

      it('calls dispatchDocumentEvent to update global To-Do counter correctly', () => {
        expect(utils.dispatchDocumentEvent).toHaveBeenCalledTimes(1);
        expect(utils.dispatchDocumentEvent).toHaveBeenCalledWith('todo:toggle', {
          detail: {
            count: 1,
          },
        });
      });
    });
  });

  describe('when design has no pending todos', () => {
    beforeEach(() => {
      createComponent({}, { mountFn: mount });
    });

    it('renders correct button text', () => {
      expect(wrapper.text()).toBe('Add a To-Do');
    });

    describe('when clicked', () => {
      beforeEach(() => {
        utils.dispatchDocumentEvent = jest.fn();
        jest.spyOn(document, 'querySelector').mockReturnValue({
          innerText: 2,
        });

        createComponent({}, { mountFn: mount });
        wrapper.trigger('click');
        return wrapper.vm.$nextTick();
      });

      it('calls `$apollo.mutate` with the `createDesignTodoMutation` mutation and variables containing `issuable_id`, `issue_id`, & `projectPath`', async () => {
        const createDesignTodoMutationVariables = {
          mutation: createDesignTodoMutation,
          update: expect.anything(),
          variables: {
            atVersion: null,
            filenames: ['my-design.jpg'],
            issueId: '1',
            issueIid: '10',
            projectPath: 'project-path',
          },
        };

        expect(mutate).toHaveBeenCalledTimes(1);
        expect(mutate).toHaveBeenCalledWith(createDesignTodoMutationVariables);
      });

      it('calls dispatchDocumentEvent to update global To-Do counter correctly', () => {
        expect(utils.dispatchDocumentEvent).toHaveBeenCalledTimes(1);
        expect(utils.dispatchDocumentEvent).toHaveBeenCalledWith('todo:toggle', {
          detail: {
            count: 3,
          },
        });
      });
    });
  });
});
