import { shallowMount } from '@vue/test-utils';
import { GlAlert } from '@gitlab/ui';
import { ApolloMutation } from 'vue-apollo';
import createFlash from '~/flash';
import DesignIndex from 'ee/design_management/pages/design/index.vue';
import DesignDiscussion from 'ee/design_management/components/design_notes/design_discussion.vue';
import DesignReplyForm from 'ee/design_management/components/design_notes/design_reply_form.vue';
import Participants from '~/sidebar/components/participants/participants.vue';
import createImageDiffNoteMutation from 'ee/design_management/graphql/mutations/createImageDiffNote.mutation.graphql';
import design from '../../mock_data/design';
import mockResponseNoDesigns from '../../mock_data/no_designs';
import { DESIGN_NOT_FOUND_ERROR } from 'ee/design_management/utils/error_messages';
import { DESIGNS_ROUTE_NAME } from 'ee/design_management/router/constants';

jest.mock('~/flash');
jest.mock('mousetrap', () => ({
  bind: jest.fn(),
  unbind: jest.fn(),
}));

describe('Design management design index page', () => {
  let wrapper;
  const newComment = 'new comment';
  const annotationCoordinates = {
    x: 10,
    y: 10,
    width: 100,
    height: 100,
  };
  const mutationVariables = {
    mutation: createImageDiffNoteMutation,
    update: expect.anything(),
    variables: {
      input: {
        body: newComment,
        noteableId: design.id,
        position: {
          headSha: 'headSha',
          baseSha: 'baseSha',
          startSha: 'startSha',
          paths: {
            newPath: 'full-design-path',
          },
          ...annotationCoordinates,
        },
      },
    },
  };
  const mutate = jest.fn().mockResolvedValue();
  const routerPush = jest.fn();

  const findDiscussions = () => wrapper.findAll(DesignDiscussion);
  const findDiscussionForm = () => wrapper.find(DesignReplyForm);
  const findParticipants = () => wrapper.find(Participants);

  function createComponent(loading = false) {
    const $apollo = {
      queries: {
        design: {
          loading,
        },
      },
      mutate,
    };

    const $router = {
      push: routerPush,
      query: {},
    };

    wrapper = shallowMount(DesignIndex, {
      propsData: { id: '1' },
      mocks: { $apollo, $router },
      stubs: {
        ApolloMutation,
      },
    });

    wrapper.setData({
      issueIid: '1',
    });
  }

  function setDesign() {
    createComponent(true);
    wrapper.vm.$apollo.queries.design.loading = false;
  }

  afterEach(() => {
    wrapper.destroy();
  });

  it('sets loading state', () => {
    createComponent(true);

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  it('renders design index', () => {
    setDesign();

    wrapper.setData({
      design,
    });

    return wrapper.vm.$nextTick().then(() => {
      expect(wrapper.element).toMatchSnapshot();
      expect(wrapper.find(GlAlert).exists()).toBe(false);
    });
  });

  it('renders participants', () => {
    setDesign();

    wrapper.setData({
      design,
    });

    return wrapper.vm.$nextTick().then(() => {
      expect(findParticipants().exists()).toBe(true);
    });
  });

  it('passes the correct amount of participants to the Participants component', () => {
    expect(findParticipants().props('participants').length).toBe(1);
  });

  describe('when has no discussions', () => {
    beforeEach(() => {
      setDesign();

      wrapper.setData({
        design: {
          ...design,
          discussions: {
            nodes: [],
          },
        },
      });
    });

    it('does not render discussions', () => {
      expect(findDiscussions().exists()).toBe(false);
    });

    it('renders a message about possibility to create a new discussion', () => {
      expect(wrapper.find('.new-discussion-disclaimer').exists()).toBe(true);
    });
  });

  describe('when has discussions', () => {
    beforeEach(() => {
      setDesign();

      wrapper.setData({
        design,
      });
    });

    it('renders correct amount of discussions', () => {
      expect(findDiscussions().length).toBe(1);
    });
  });

  it('opens a new discussion form', () => {
    setDesign();

    wrapper.setData({
      design: {
        ...design,
        discussions: {
          nodes: [],
        },
      },
    });

    wrapper.vm.openCommentForm({ x: 0, y: 0 });

    return wrapper.vm.$nextTick().then(() => {
      expect(findDiscussionForm().exists()).toBe(true);
    });
  });

  it('sends a mutation on submitting form and closes form', () => {
    setDesign();

    wrapper.setData({
      design: {
        ...design,
        discussions: {
          nodes: [],
        },
      },
      annotationCoordinates,
      comment: newComment,
    });

    return wrapper.vm
      .$nextTick()
      .then(() => {
        findDiscussionForm().vm.$emit('submitForm');

        expect(mutate).toHaveBeenCalledWith(mutationVariables);
        return mutate({ variables: mutationVariables });
      })
      .then(() => {
        expect(findDiscussionForm().exists()).toBe(false);
      });
  });

  it('closes the form and clears the comment on canceling form', () => {
    setDesign();

    wrapper.setData({
      design: {
        ...design,
        discussions: {
          nodes: [],
        },
      },
      annotationCoordinates,
      comment: newComment,
    });

    return wrapper.vm
      .$nextTick()
      .then(() => {
        findDiscussionForm().vm.$emit('cancelForm');

        expect(wrapper.vm.comment).toBe('');
        return wrapper.vm.$nextTick();
      })
      .then(() => {
        expect(findDiscussionForm().exists()).toBe(false);
      });
  });

  describe('with error', () => {
    beforeEach(() => {
      setDesign();

      wrapper.setData({
        design: {
          ...design,
          discussions: {
            nodes: [],
          },
        },
        errorMessage: 'woops',
      });
    });

    it('GlAlert is rendered in correct position with correct content', () => {
      expect(wrapper.element).toMatchSnapshot();
    });
  });

  describe('onDesignQueryResult', () => {
    describe('with no designs', () => {
      it('redirects to /designs', () => {
        createComponent(true);
        wrapper.setMethods({
          onQueryError: jest.fn(),
        });

        wrapper.vm.onDesignQueryResult(mockResponseNoDesigns);
        expect(wrapper.vm.onQueryError).toHaveBeenCalledTimes(1);
        expect(wrapper.vm.onQueryError).toHaveBeenCalledWith(DESIGN_NOT_FOUND_ERROR);
      });
    });
  });

  describe('onQueryError', () => {
    it('redirects to /designs and displays flash', () => {
      createComponent(true);

      wrapper.vm.onQueryError(DESIGN_NOT_FOUND_ERROR);

      expect(createFlash).toHaveBeenCalledTimes(1);
      expect(createFlash).toHaveBeenCalledWith(DESIGN_NOT_FOUND_ERROR);
      expect(routerPush).toHaveBeenCalledTimes(1);
      expect(routerPush).toHaveBeenCalledWith({ name: DESIGNS_ROUTE_NAME });
    });
  });
});
