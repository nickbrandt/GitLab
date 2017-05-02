import Vue from 'vue';
import eventHub from '~/issuable/related_issues/event_hub';
import RelatedIssuesBlock from '~/issuable/related_issues/components/related_issues_block.vue';

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(RelatedIssuesBlock);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

const issuable1 = {
  reference: 'foo/bar#123',
  title: 'some title',
  path: '/foo/bar/issues/123',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};

describe('RelatedIssuesBlock', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with defaults', () => {
    beforeEach(() => {
      vm = createComponent();
    });

    it('unable to add new related issues', () => {
      expect(vm.$refs['issue-count-holder-add-button']).toBeUndefined();
    });

    it('add related issues form is hidden', () => {
      expect(vm.$refs['related-issues-add-related-issues-form']).toBeUndefined();
    });
  });

  describe('with `canAddRelatedIssues=true`', () => {
    beforeEach(() => {
      vm = createComponent({
        canAddRelatedIssues: true,
      });
    });

    it('can add new related issues', () => {
      expect(vm.$refs['issue-count-holder-add-button']).toBeDefined();
    });
  });

  describe('with `isAddRelatedIssuesFormVisible=true`', () => {
    beforeEach(() => {
      vm = createComponent({
        isAddRelatedIssuesFormVisible: true,
      });
    });

    it('shows add related issues form', () => {
      expect(vm.$refs['related-issues-add-related-issues-form']).toBeDefined();
    });
  });

  describe('methods', () => {
    let showAddRelatedIssuesFormSpy;
    let relatedIssueRemoveRequestSpy;

    beforeEach(() => {
      vm = createComponent({
        relatedIssues: [
          issuable1,
        ],
      });
      showAddRelatedIssuesFormSpy = jasmine.createSpy('spy');
      relatedIssueRemoveRequestSpy = jasmine.createSpy('spy');
      eventHub.$on('showAddRelatedIssuesForm', showAddRelatedIssuesFormSpy);
      eventHub.$on('relatedIssueRemoveRequest', relatedIssueRemoveRequestSpy);
    });

    afterEach(() => {
      eventHub.$off('showAddRelatedIssuesForm', showAddRelatedIssuesFormSpy);
      eventHub.$off('relatedIssueRemoveRequest', relatedIssueRemoveRequestSpy);
    });

    it('when expanding add related issue form', () => {
      expect(showAddRelatedIssuesFormSpy).not.toHaveBeenCalled();
      vm.showAddRelatedIssuesForm();
      expect(showAddRelatedIssuesFormSpy).toHaveBeenCalled();
    });

    it('when remove related issue', () => {
      expect(relatedIssueRemoveRequestSpy).not.toHaveBeenCalled();
      vm.onRelatedIssueRemoveRequest(issuable1.reference);
      expect(relatedIssueRemoveRequestSpy).toHaveBeenCalledWith(issuable1.reference);
    });
  });
});
