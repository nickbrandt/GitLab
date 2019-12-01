import { createLocalVue, shallowMount } from '@vue/test-utils';
import createFlash from '~/flash';
import VueRouter from 'vue-router';
import Index from 'ee/design_management/pages/index.vue';
import uploadDesignQuery from 'ee/design_management/graphql/mutations/uploadDesign.mutation.graphql';
import DesignDestroyer from 'ee/design_management/components/design_destroyer.vue';

const localVue = createLocalVue();
localVue.use(VueRouter);
const router = new VueRouter({
  routes: [
    {
      name: 'designs',
      path: '/designs',
      component: Index,
    },
  ],
});

jest.mock('~/flash.js');

const mockDesigns = [
  {
    id: 'design-1',
    image: 'design-1-image',
    filename: 'design-1-name',
    event: 'NONE',
    notesCount: 0,
  },
  {
    id: 'design-2',
    image: 'design-2-image',
    filename: 'design-2-name',
    event: 'NONE',
    notesCount: 1,
  },
  {
    id: 'design-3',
    image: 'design-3-image',
    filename: 'design-3-name',
    event: 'NONE',
    notesCount: 0,
  },
];

const mockVersion = {
  node: {
    id: 'gid://gitlab/DesignManagement::Version/1',
  },
};

describe('Design management index page', () => {
  let mutate;
  let wrapper;

  const findDesignCheckboxes = () => wrapper.findAll('.design-checkbox');
  const findSelectAllButton = () => wrapper.find('.js-select-all');
  const findDeleteButton = () => wrapper.find('deletebutton-stub');

  function createComponent({
    loading = false,
    designs = [],
    allVersions = [],
    createDesign = true,
  } = {}) {
    mutate = jest.fn(() => Promise.resolve());
    const $apollo = {
      queries: {
        designs: {
          loading,
        },
        permissions: {
          loading,
        },
      },
      mutate,
    };

    wrapper = shallowMount(Index, {
      sync: false,
      mocks: { $apollo },
      localVue,
      router,
      stubs: { DesignDestroyer },
    });

    wrapper.setData({
      designs,
      allVersions,
      issueIid: '1',
      permissions: {
        createDesign,
      },
    });
  }

  afterEach(() => {
    wrapper.destroy();
  });

  describe('designs', () => {
    it('renders loading icon', () => {
      createComponent({ loading: true });

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders error', () => {
      createComponent();

      wrapper.setData({ error: true });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('renders empty text', () => {
      createComponent();

      expect(wrapper.element).toMatchSnapshot();
    });

    it('renders designs list and header with upload button', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });

    it('does not render toolbar when there is no permission', () => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion], createDesign: false });

      return wrapper.vm.$nextTick().then(() => {
        expect(wrapper.element).toMatchSnapshot();
      });
    });
  });

  describe('onUploadDesign', () => {
    it('calls apollo mutate', () => {
      createComponent();

      return wrapper.vm
        .onUploadDesign([
          {
            name: 'test',
          },
        ])
        .then(() => {
          expect(mutate).toHaveBeenCalledWith({
            context: {
              hasUpload: true,
            },
            mutation: uploadDesignQuery,
            variables: {
              files: [{ name: 'test' }],
              projectPath: '',
              iid: '1',
            },
            update: expect.anything(),
            optimisticResponse: {
              __typename: 'Mutation',
              designManagementUpload: {
                __typename: 'DesignManagementUploadPayload',
                designs: [
                  {
                    __typename: 'Design',
                    id: expect.anything(),
                    image: '',
                    filename: 'test',
                    fullPath: '',
                    event: 'NONE',
                    notesCount: 0,
                    diffRefs: {
                      __typename: 'DiffRefs',
                      baseSha: '',
                      startSha: '',
                      headSha: '',
                    },
                    discussions: {
                      __typename: 'DesignDiscussion',
                      edges: [],
                    },
                    versions: {
                      __typename: 'DesignVersionConnection',
                      edges: {
                        __typename: 'DesignVersionEdge',
                        node: {
                          __typename: 'DesignVersion',
                          id: expect.anything(),
                          sha: expect.anything(),
                        },
                      },
                    },
                  },
                ],
              },
            },
          });
        });
    });

    it('does not call apollo mutate if createDesign is false', () => {
      createComponent({ createDesign: false });

      wrapper.vm.onUploadDesign([]);

      expect(mutate).not.toHaveBeenCalled();
    });

    it('sets isSaving', () => {
      createComponent();

      const uploadDesign = wrapper.vm.onUploadDesign([
        {
          name: 'test',
        },
      ]);

      expect(wrapper.vm.isSaving).toBe(true);

      return uploadDesign.then(() => {
        expect(wrapper.vm.isSaving).toBe(false);
      });
    });

    describe('upload count limit', () => {
      const MAXIMUM_FILE_UPLOAD_LIMIT = 10;

      afterEach(() => {
        createFlash.mockReset();
      });

      it('does not warn when the max files are uploaded', () => {
        createComponent();

        wrapper.vm.onUploadDesign(new Array(MAXIMUM_FILE_UPLOAD_LIMIT).fill(mockDesigns[0]));

        expect(createFlash).not.toHaveBeenCalled();
      });

      it('warns when too many files are uploaded', () => {
        createComponent();

        wrapper.vm.onUploadDesign(new Array(MAXIMUM_FILE_UPLOAD_LIMIT + 1).fill(mockDesigns[0]));

        expect(createFlash).toHaveBeenCalled();
      });
    });
  });

  describe('on latest version', () => {
    beforeEach(() => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });
    });

    it('renders design checkboxes', () => {
      expect(findDesignCheckboxes().length).toBe(mockDesigns.length);
    });

    it('renders Delete selected button', () => {
      expect(findDeleteButton().exists()).toBe(true);
    });

    it('renders a button with Select all text', () => {
      expect(findSelectAllButton().exists()).toBe(true);
      expect(findSelectAllButton().text()).toBe('Select all');
    });

    it('adds two designs to selected designs when their checkboxes are checked', () => {
      findDesignCheckboxes()
        .at(0)
        .trigger('click');
      findDesignCheckboxes()
        .at(1)
        .trigger('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(findDeleteButton().exists()).toBe(true);
        expect(findSelectAllButton().text()).toBe('Deselect all');
        findDeleteButton().vm.$emit('deleteSelectedDesigns');
        const [{ variables }] = mutate.mock.calls[0];
        expect(variables.filenames).toStrictEqual([
          mockDesigns[0].filename,
          mockDesigns[1].filename,
        ]);
      });
    });

    it('adds all designs to selected designs when Select All button is clicked', () => {
      findSelectAllButton().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(findDeleteButton().props().hasSelectedDesigns).toBe(true);
        expect(findSelectAllButton().text()).toBe('Deselect all');
        expect(wrapper.vm.selectedDesigns).toEqual(mockDesigns.map(design => design.filename));
      });
    });

    it('removes all designs from selected designs when at least one design was selected', () => {
      findDesignCheckboxes()
        .at(0)
        .trigger('click');
      findSelectAllButton().vm.$emit('click');

      return wrapper.vm.$nextTick().then(() => {
        expect(findDeleteButton().props().hasSelectedDesigns).toBe(false);
        expect(findSelectAllButton().text()).toBe('Select all');
        expect(wrapper.vm.selectedDesigns).toEqual([]);
      });
    });
  });

  describe('on non-latest version', () => {
    beforeEach(() => {
      createComponent({ designs: mockDesigns, allVersions: [mockVersion] });

      router.replace({
        name: 'designs',
        query: {
          version: '2',
        },
      });
    });

    it('does not render design checkboxes', () => {
      expect(findDesignCheckboxes().length).toBe(0);
    });

    it('does not render Delete selected button', () => {
      expect(findDeleteButton().exists()).toBe(false);
    });

    it('does not render Select All button', () => {
      expect(findSelectAllButton().exists()).toBe(false);
    });
  });
});
