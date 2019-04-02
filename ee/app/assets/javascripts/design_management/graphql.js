import Vue from 'vue';
import VueApollo from 'vue-apollo';
import _ from 'underscore';
import createDefaultClient from '~/lib/graphql';
import allDesigns from './queries/allDesigns.graphql';

Vue.use(VueApollo);

const createMockDesign = id => ({
  id: Number(id),
  image: 'http://via.placeholder.com/1000',
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
  Query: {
    design(ctx, { id }) {
      return designsStore.find(design => design.id === id);
    },
  },
  Mutation: {
    uploadDesign(ctx, { files }, { cache }) {
      const previousDesigns = cache.readQuery({ query: allDesigns });
      const designs = Array.from(files).map(n => ({
        ...createMockDesign(_.uniqueId()),
        name: n.name,
        commentsCount: 0,
      }));
      const data = {
        designs: designs.concat(previousDesigns.designs),
      };

      designsStore.unshift(...designs);

      cache.writeQuery({ query: allDesigns, data });

      return designs;
    },
  },
});

defaultClient.cache.writeData({
  data: {
    designs: designsStore,
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
