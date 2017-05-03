import _ from 'underscore';
import RelatedIssuesStore from '~/issuable/related_issues/stores/related_issues_store';

const issuable1 = {
  reference: 'foo/bar#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};

describe('RelatedIssuesStore', () => {
  let store;

  beforeEach(() => {
    store = new RelatedIssuesStore();
  });

  describe('getIssuesFromReferences', () => {
    it('with full reference', () => {
      store.state.issueMap = {
        [issuable1.reference]: issuable1,
      };
      expect(store.getIssuesFromReferences(['foo/bar#123'], 'foo', 'bar')).toEqual([{
        ..._.omit(issuable1, 'destroy_relation_path'),
        reference: '#123',
        canRemove: true,
      }]);
    });

    it('with project reference', () => {
      store.state.issueMap = {
        [issuable1.reference]: issuable1,
      };
      expect(store.getIssuesFromReferences(['bar#123'], 'foo', 'bar')).toEqual([{
        ..._.omit(issuable1, 'destroy_relation_path'),
        reference: '#123',
        canRemove: true,
      }]);
    });

    it('with issue number reference', () => {
      store.state.issueMap = {
        [issuable1.reference]: issuable1,
      };
      expect(store.getIssuesFromReferences(['#123'], 'foo', 'bar')).toEqual([{
        ..._.omit(issuable1, 'destroy_relation_path'),
        reference: '#123',
        canRemove: true,
      }]);
    });
  });

  describe('addToIssueMap', () => {
    it('defaults to empty object hash', () => {
      expect(store.state.issueMap).toEqual({});
    });

    it('add issue', () => {
      store.addToIssueMap(issuable1.reference, issuable1);

      expect(store.state.issueMap).toEqual({
        [issuable1.reference]: issuable1,
      });
    });
  });

  describe('setRelatedIssues', () => {
    it('defaults to empty array', () => {
      expect(store.state.relatedIssues).toEqual([]);
    });

    it('add reference', () => {
      const relatedIssues = ['#123'];
      store.setRelatedIssues(relatedIssues);

      expect(store.state.relatedIssues).toEqual(relatedIssues);
    });
  });

  describe('setPendingRelatedIssues', () => {
    it('defaults to empty array', () => {
      expect(store.state.pendingRelatedIssues).toEqual([]);
    });

    it('add reference', () => {
      const relatedIssues = ['#123'];
      store.setPendingRelatedIssues(relatedIssues);

      expect(store.state.pendingRelatedIssues).toEqual(relatedIssues);
    });
  });

  describe('setRequestError', () => {
    it('defaults to null', () => {
      expect(store.state.requestError).toEqual(null);
    });

    it('set error', () => {
      const err = new Error('failed fetching things');
      store.setRequestError(err);

      expect(store.state.requestError).toEqual(err);
    });
  });

  describe('setIsAddRelatedIssuesFormVisible', () => {
    it('defaults to false', () => {
      expect(store.state.isAddRelatedIssuesFormVisible).toEqual(false);
    });

    it('set to true', () => {
      store.setIsAddRelatedIssuesFormVisible(true);

      expect(store.state.isAddRelatedIssuesFormVisible).toEqual(true);
    });
  });

  describe('setAddRelatedIssuesFormInputValue', () => {
    it('defaults to empty string', () => {
      expect(store.state.addRelatedIssuesFormInputValue).toEqual('');
    });

    it('set to true', () => {
      store.setAddRelatedIssuesFormInputValue('#123');

      expect(store.state.addRelatedIssuesFormInputValue).toEqual('#123');
    });
  });
});
