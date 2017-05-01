import Vue from 'vue';
import IssueToken from '~/issuable/related_issues/components/issue_token.vue';

const createComponent = (propsData) => {
  const Component = Vue.extend(IssueToken);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

describe('IssueToken', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('methods', () => {
    let removeRequestSpy;

    beforeEach(() => {
      vm = createComponent({
        isEnabled: false,
      });
      removeRequestSpy = jasmine.createSpy('spy');
      vm.$on('removeRequest', removeRequestSpy);
    });

    afterEach(() => {
      vm.$off('removeRequest', removeRequestSpy);
    });

    it('when getting checked', () => {
      expect(removeRequestSpy).not.toHaveBeenCalled();
      vm.onRemoveRequest();
      expect(removeRequestSpy).toHaveBeenCalled();
    });
  });
});
