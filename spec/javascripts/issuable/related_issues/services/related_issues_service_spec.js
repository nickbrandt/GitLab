import RelatedIssuesService from '~/issuable/related_issues/services/related_issues_service';

const issuable1 = {
  reference: 'foo/bar#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};

fdescribe('RelatedIssuesService', () => {
  let service;

  beforeEach(() => {
    service = new RelatedIssuesService('');
  });

  it('fetchRelatedIssues', (done) => {
    spyOn(service.relatedIssuesResource, 'get').and.returnValue(Promise.resolve({
      data: [
        issuable1,
      ],
    }));

    service.fetchRelatedIssues()
      .then((relatedIssues) => {
        expect(relatedIssues).toEqual([issuable1]);
        done();
      })
      .catch((err) => {
        done.fail(`Failed to fetch incoming email:\n${err}`);
      });
  });
});
