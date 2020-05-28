import { shallowMount } from '@vue/test-utils';
import { ApolloMutation } from 'vue-apollo';
import { GlForm } from '@gitlab/ui';
import { visitUrl } from '~/lib/utils/url_utility';
import IterationForm from 'ee/iterations/components/iteration_form.vue';
import createIteration from 'ee/iterations/queries/create_iteration.mutation.graphql';
import { TEST_HOST } from 'helpers/test_constants';

jest.mock('~/lib/utils/url_utility');

describe('Iteration Form', () => {
  let wrapper;
  const groupPath = 'gitlab-org';
  const successfulMutation = { data: { createIteration: { iteration: {}, errors: [] } } };
  const failedMutation = {
    data: { createIteration: { iteration: {}, errors: ['alas, your data is unchanged'] } },
  };
  const props = { groupPath, iterationsListPath: TEST_HOST };

  function createComponent({ mutationResult = successfulMutation } = {}) {
    wrapper = shallowMount(IterationForm, {
      propsData: props,
      stubs: {
        ApolloMutation,
        MarkdownField: '<div><slot name="textarea"></slot></div>',
      },
      mocks: {
        $apollo: {
          mutate: jest.fn().mockResolvedValue(mutationResult),
        },
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
    wrapper = null;
  });

  const findTitle = () => wrapper.find('#iteration-title');
  const findDescription = () => wrapper.find('#iteration-description');
  const findStartDate = () => wrapper.find('#iteration-start-date');
  const findDueDate = () => wrapper.find('#iteration-due-date');
  const findSaveButton = () => wrapper.find('[data-testid="save-iteration"]');
  const findCancelButton = () => wrapper.find('[data-testid="cancel-iteration"]');

  it('renders a form', () => {
    createComponent();
    expect(wrapper.find(GlForm).exists()).toBe(true);
  });

  it('cancel button links to list page', () => {
    createComponent();
    expect(findCancelButton().attributes('href')).toBe(TEST_HOST);
  });

  describe('save', () => {
    it('trigges mutation with form data', () => {
      createComponent();

      const title = 'Iteration 5';
      const description = 'The fifth iteration';
      const startDate = '2020-05-05';
      const dueDate = '2020-05-25';

      findTitle().vm.$emit('input', title);
      findDescription().setValue(description);
      findStartDate().vm.$emit('input', startDate);
      findDueDate().vm.$emit('input', dueDate);

      findSaveButton().vm.$emit('click');

      expect(wrapper.vm.$apollo.mutate).toHaveBeenCalledWith({
        mutation: createIteration,
        variables: {
          input: {
            groupPath,
            title,
            description,
            startDate,
            dueDate,
          },
        },
      });
    });

    it('loading=true immediately', () => {
      createComponent();

      wrapper.vm.save();

      expect(wrapper.vm.loading).toBeTruthy();
    });

    it('redirects to Iteration page on success', () => {
      createComponent();

      return wrapper.vm.save().then(() => {
        expect(findSaveButton().props('loading')).toBeTruthy();
        expect(visitUrl).toHaveBeenCalled();
      });
    });

    it('loading=false on error', () => {
      createComponent({ mutationResult: failedMutation });

      return wrapper.vm.save().then(() => {
        expect(findSaveButton().props('loading')).toBeFalsy();
      });
    });
  });
});
