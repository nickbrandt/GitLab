import { shallowMount } from '@vue/test-utils';
import Index from 'ee/design_management/pages/index.vue';
import uploadDesignQuery from 'ee/design_management/queries/uploadDesign.graphql';

describe('Design management index page', () => {
  const mutate = jest.fn(() => Promise.resolve());
  let vm;

  function createComponent(loading = false) {
    const $apollo = {
      queries: {
        designs: {
          loading,
        },
      },
      mutate,
    };

    vm = shallowMount(Index, {
      mocks: { $apollo },
    });
  }

  describe('designs', () => {
    it('renders loading icon', () => {
      createComponent(true);

      expect(vm.element).toMatchSnapshot();
    });

    it('renders error', () => {
      createComponent();

      vm.setData({ error: true });

      expect(vm.element).toMatchSnapshot();
    });

    it('renders empty text', () => {
      createComponent();

      expect(vm.element).toMatchSnapshot();
    });

    it('renders designs list', () => {
      createComponent();

      vm.setData({ designs: ['design'] });

      expect(vm.element).toMatchSnapshot();
    });
  });

  describe('onUploadDesign', () => {
    it('calls apollo mutate', () => {
      createComponent();

      return vm.vm
        .onUploadDesign([
          {
            name: 'test',
          },
        ])
        .then(() => {
          expect(mutate).toHaveBeenCalledWith({
            mutation: uploadDesignQuery,
            update: expect.any(Function),
            variables: {
              name: 'test',
            },
            optimisticResponse: {
              __typename: 'Mutation',
              uploadDesign: {
                __typename: 'Design',
                id: -1,
                image: '',
                name: 'test',
                commentsCount: 0,
                updatedAt: expect.any(String),
              },
            },
          });
        });
    });

    it('sets isSaving', () => {
      createComponent();

      const uploadDesign = vm.vm.onUploadDesign([
        {
          name: 'test',
        },
      ]);

      expect(vm.vm.isSaving).toBe(true);

      return uploadDesign.then(() => {
        expect(vm.vm.isSaving).toBe(false);
      });
    });
  });
});
