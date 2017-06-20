import MergeRequestStore from '~/vue_merge_request_widget/ee/stores/mr_widget_store';

describe('MergeRequestStore', () => {
  const store = new MergeRequestStore({ current_user: {} });

  describe('initApprovals', () => {
    let data = {};

    it('sets approvals to approvals data array', () => {
      data = { approvals: [{}, {}] };

      store.initApprovals(data);

      expect(store.approvals).toBe(data.approvals);
    });

    it('sets approvals to null if no approvals data', () => {
      data = { approvals: undefined };

      store.initApprovals(data);

      expect(store.approvals).toBe(null);
    });
  });
});
