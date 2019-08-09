export default {
  id: 'design-id',
  filename: 'test.jpg',
  fullPath: 'full-design-path',
  image: 'test.jpg',
  updatedAt: '01-01-2019',
  updatedBy: {
    name: 'test',
  },
  discussions: {
    edges: [
      {
        node: {
          id: 'discussion-id',
          replyId: 'discussion-reply-id',
          notes: {
            edges: [
              {
                node: {
                  id: 'note-id',
                  body: '123',
                },
              },
            ],
          },
        },
      },
    ],
  },
  diffRefs: {
    headSha: 'headSha',
    baseSha: 'baseSha',
    startSha: 'startSha',
  },
};
