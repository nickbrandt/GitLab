import Vue from 'vue';
import IssueToken from '~/issuable/related_issues/components/issue_token.vue';

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(IssueToken);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

describe('IssueToken', () => {
  const reference = 'foo/bar#123';
  const title = 'some title';

  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('with reference supplied', () => {
    beforeEach(() => {
      vm = createComponent({
        reference,
      });
    });

    it('shows reference', () => {
      expect(vm.$el.textContent.trim()).toEqual(reference);
    });
  });

  describe('with reference and title supplied', () => {
    beforeEach(() => {
      vm = createComponent({
        reference,
        title,
      });
    });

    it('shows reference and title', () => {
      expect(vm.$el.querySelector('.issue-token-reference').textContent.trim()).toEqual(reference);
      expect(vm.$el.querySelector('.issue-token-title').textContent.trim()).toEqual(title);
    });
  });

  describe('with path supplied', () => {
    const path = '/foo/bar/issues/123';
    beforeEach(() => {
      vm = createComponent({
        reference,
        title,
        path,
      });
    });

    it('links reference and title', () => {
      expect(vm.$el.querySelector('a.issue-token-reference').getAttribute('href')).toEqual(path);
      expect(vm.$el.querySelector('a.issue-token-title-link').getAttribute('href')).toEqual(path);
    });
  });

  describe('with state supplied', () => {
    describe('`state: \'opened\'`', () => {
      beforeEach(() => {
        vm = createComponent({
          reference,
          state: 'opened',
        });
      });

      it('shows green circle icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-open.fa.fa-circle-o')).toBeDefined();
      });
    });

    describe('`state: \'closed\'`', () => {
      beforeEach(() => {
        vm = createComponent({
          reference,
          state: 'closed',
        });
      });

      it('shows green circle icon', () => {
        expect(vm.$el.querySelector('.issue-token-state-icon-closed.fa.fa-minus')).toBeDefined();
      });
    });
  });

  describe('with reference, title, state', () => {
    const state = 'opened';
    beforeEach(() => {
      vm = createComponent({
        reference,
        title,
        state,
      });
    });

    it('shows reference', () => {
      expect(vm.$el.querySelector('.issue-token-reference').getAttribute('aria-label')).toEqual(`${state} ${reference} ${title}`);
    });
  });

  describe('with canRemove supplied', () => {
    describe('`canRemove: false` (default)', () => {
      beforeEach(() => {
        vm = createComponent({
          reference,
        });
      });

      it('does not have remove button', () => {
        expect(vm.$el.querySelector('.issue-token-remove-button')).toBeNull();
      });
    });

    describe('`canRemove: true`', () => {
      beforeEach(() => {
        vm = createComponent({
          reference,
          canRemove: true,
        });
      });

      it('has remove button', () => {
        expect(vm.$el.querySelector('.issue-token-remove-button')).toBeDefined();
      });
    });
  });

  describe('methods', () => {
    let removeRequestSpy;

    beforeEach(() => {
      vm = createComponent({
        reference,
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
