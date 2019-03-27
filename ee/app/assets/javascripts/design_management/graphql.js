import Vue from 'vue';
import VueApollo from 'vue-apollo';
import _ from 'underscore';
import createDefaultClient from '~/lib/graphql';
import allDesigns from './queries/allDesigns.graphql';

Vue.use(VueApollo);

const createMockDesign = id => ({
  id: Number(id),
  image: 'http://via.placeholder.com/300',
  name: 'test.jpg',
  commentsCount: 2,
  updatedAt: new Date().toString(),
  updatedBy: {
    name: 'Test Name',
    __typename: 'Author',
  },
  __typename: 'Design',
});

const designsStore = [
  createMockDesign(_.uniqueId()),
  createMockDesign(_.uniqueId()),
  createMockDesign(_.uniqueId()),
  createMockDesign(_.uniqueId()),
  createMockDesign(_.uniqueId()),
];

const defaultClient = createDefaultClient({
  defaults: {
    designs: designsStore,
  },
  resolvers: {
    Query: {
      design(ctx, { id }) {
        return designsStore.find(design => design.id === id);
      },
    },
    Mutation: {
      uploadDesign(ctx, { name }, { cache }) {
        const designs = name.map(n => ({
          ...createMockDesign(_.uniqueId()),
          name: n,
          commentsCount: 0,
        }));

        cache.writeData({ data: designs });

        return designs;
      },
    },
  },
});

defaultClient
  .watchQuery({
    query: allDesigns,
  })
  .subscribe(({ data: { designs } }) => {
    const badge = document.querySelector('.js-designs-count');

    if (badge) {
      badge.textContent = designs.length;
    }
  });

export default new VueApollo({
  defaultClient,
});
