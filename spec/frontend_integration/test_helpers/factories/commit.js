// eslint-disable-next-line import/prefer-default-export
import { withProps } from '../utils/obj';
import { getCommit } from '../fixtures';
import { generateCommitId } from './commit_id';

// eslint-disable-next-line import/prefer-default-export
export const createNewCommit = ({ id: idParam, message }, orig = getCommit()) => {
  const id = idParam || generateCommitId();

  return withProps(orig, {
    id,
    short_id: id.substr(0, 8),
    message,
    title: message,
    web_url: orig.web_url.replace(orig.id, id),
    parent_ids: [orig.id],
  });
};
