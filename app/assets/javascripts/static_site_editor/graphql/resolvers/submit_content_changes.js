import submitContentChanges from '../../services/submit_content_changes';
import savedContentMetaQuery from '../queries/saved_content_meta.query.graphql';

const submitContentChangesResolver = (
  _root,
  { project: projectId, username, sourcePath, content },
  { cache },
) => {
  return submitContentChanges({ projectId, username, sourcePath, content }).then(
    savedContentMeta => {
      cache.writeQuery({
        query: savedContentMetaQuery,
        data: {
          savedContentMeta: {
            __typename: 'SavedContentMeta',
            ...savedContentMeta,
          },
        },
      });

      return null;
    },
  );
};

export default submitContentChangesResolver;
