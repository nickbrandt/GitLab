let version = 1;

const resolvers = {
  DesignVersion: {
    versionNumber: () => {
      version += 1;
      return version;
    },
    author: () => ({
      avatarUrl:
        'https://www.gravatar.com/avatar/e64c7d89f26bd1972efa854d13d7dd61?s=80&d=identicon',
      name: 'Administrator',
      username: 'root',
      webUrl: 'http://git.lab:3000/root',
      __typename: 'User',
    }),
    createdAt: () => '2019-11-13T16:08:11Z',
  },
};

export default resolvers;
