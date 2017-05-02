import Vue from 'vue';
import RelatedIssuesRoot from '~/issuable/related_issues/components/related_issues_root.vue';

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(RelatedIssuesRoot);

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

describe('RelatedIssuesRoot', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });


});
