import Vue from 'vue';
import MockAdapter from 'axios-mock-adapter';
import relatedIssuesRoot from 'ee/related_issues/components/related_issues_root.vue';
import relatedIssuesService from 'ee/related_issues/services/related_issues_service';
import {
  defaultProps,
  issuable1,
  issuable2,
} from 'spec/vue_shared/components/issue/related_issuable_mock_data';
import axios from '~/lib/utils/axios_utils';

describe('RelatedIssuesRoot', () => {
  let RelatedIssuesRoot;
  let vm;
  let mock;

  beforeEach(() => {
    RelatedIssuesRoot = Vue.extend(relatedIssuesRoot);
    mock = new MockAdapter(axios);
  });

  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
    mock.restore();
  });

  describe('methods', () => {
    describe('onRelatedIssueRemoveRequest', () => {
      beforeEach(done => {
        spyOn(relatedIssuesService.prototype, 'fetchRelatedIssues').and.returnValue(
          Promise.reject(),
        );

        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();

        setTimeout(() => {
          vm.store.setRelatedIssues([issuable1]);
          done();
        });
      });

      it('remove related issue and succeeds', done => {
        mock.onAny().reply(200, { issues: [] });

        vm.onRelatedIssueRemoveRequest(issuable1.id);

        setTimeout(() => {
          expect(vm.state.relatedIssues).toEqual([]);

          done();
        });
      });

      it('remove related issue, fails, and restores to related issues', done => {
        mock.onAny().reply(422, {});

        vm.onRelatedIssueRemoveRequest(issuable1.id);

        setTimeout(() => {
          expect(vm.state.relatedIssues.length).toEqual(1);
          expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);

          done();
        });
      });
    });

    describe('onToggleAddRelatedIssuesForm', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('toggle related issues form to visible', () => {
        vm.onToggleAddRelatedIssuesForm();

        expect(vm.isFormVisible).toEqual(true);
      });

      it('show add related issues form to hidden', () => {
        vm.isFormVisible = true;

        vm.onToggleAddRelatedIssuesForm();

        expect(vm.isFormVisible).toEqual(false);
      });
    });

    describe('onPendingIssueRemoveRequest', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.store.setPendingReferences([issuable1.reference]);
      });

      it('remove pending related issue', () => {
        expect(vm.state.pendingReferences.length).toEqual(1);

        vm.onPendingIssueRemoveRequest(0);

        expect(vm.state.pendingReferences.length).toEqual(0);
      });
    });

    describe('onPendingFormSubmit', () => {
      beforeEach(() => {
        spyOn(relatedIssuesService.prototype, 'fetchRelatedIssues').and.returnValue(
          Promise.reject(),
        );
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();

        spyOn(vm, 'processAllReferences').and.callThrough();
        spyOn(vm.service, 'addRelatedIssues').and.callThrough();
      });

      it('processes references before submitting', () => {
        const input = '#123';

        vm.onPendingFormSubmit(input);

        expect(vm.processAllReferences).toHaveBeenCalledWith(input);
        expect(vm.service.addRelatedIssues).toHaveBeenCalledWith([input]);
      });

      it('submit zero pending issue as related issue', done => {
        vm.store.setPendingReferences([]);
        vm.onPendingFormSubmit();

        setTimeout(() => {
          expect(vm.state.pendingReferences.length).toEqual(0);
          expect(vm.state.relatedIssues.length).toEqual(0);

          done();
        });
      });

      it('submit pending issue as related issue', done => {
        mock.onAny().reply(200, {
          issuables: [issuable1],
          result: {
            message: 'something was successfully related',
            status: 'success',
          },
        });

        vm.store.setPendingReferences([issuable1.reference]);
        vm.onPendingFormSubmit();

        setTimeout(() => {
          expect(vm.state.pendingReferences.length).toEqual(0);
          expect(vm.state.relatedIssues.length).toEqual(1);
          expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);

          done();
        });
      });

      it('submit multiple pending issues as related issues', done => {
        mock.onAny().reply(200, {
          issuables: [issuable1, issuable2],
          result: {
            message: 'something was successfully related',
            status: 'success',
          },
        });

        vm.store.setPendingReferences([issuable1.reference, issuable2.reference]);
        vm.onPendingFormSubmit();

        setTimeout(() => {
          expect(vm.state.pendingReferences.length).toEqual(0);
          expect(vm.state.relatedIssues.length).toEqual(2);
          expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);
          expect(vm.state.relatedIssues[1].id).toEqual(issuable2.id);

          done();
        });
      });

      // https://gitlab.com/gitlab-org/gitlab/issues/38410
      // eslint-disable-next-line jasmine/no-disabled-tests
      xit('displays a message from the backend upon error', done => {
        const input = '#123';
        const message = 'error';

        mock.onAny().reply(409, { message });
        document.body.innerHTML += '<div class="flash-container"></div>';

        vm.onPendingFormSubmit(input);

        setTimeout(() => {
          expect(document.querySelector('.flash-text').innerText.trim()).toContain(message);
          document.querySelector('.flash-container').remove();
          done();
        });
      });
    });

    describe('onPendingFormCancel', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
        vm.isFormVisible = true;
        vm.inputValue = 'foo';
      });

      it('when canceling and hiding add issuable form', () => {
        vm.onPendingFormCancel();

        expect(vm.isFormVisible).toEqual(false);
        expect(vm.inputValue).toEqual('');
        expect(vm.state.pendingReferences.length).toEqual(0);
      });
    });

    describe('fetchRelatedIssues', () => {
      beforeEach(done => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();

        mock.onAny().reply(200, [issuable1, issuable2]);

        // wait for internal call to fetchRelatedIssues to resolve
        setTimeout(done);
      });

      it('sets isFetching while fetching', done => {
        vm.fetchRelatedIssues();

        expect(vm.isFetching).toEqual(true);

        setTimeout(() => {
          expect(vm.isFetching).toEqual(false);

          done();
        });
      });

      it('should fetch related issues', done => {
        Vue.nextTick(() => {
          expect(vm.state.relatedIssues.length).toEqual(2);
          expect(vm.state.relatedIssues[0].id).toEqual(issuable1.id);
          expect(vm.state.relatedIssues[1].id).toEqual(issuable2.id);

          done();
        });
      });
    });

    describe('onInput', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('fill in issue number reference and adds to pending related issues', () => {
        const input = '#123 ';
        vm.onInput({
          untouchedRawReferences: [input.trim()],
          touchedReference: input,
        });

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual('#123');
      });

      it('fill in with full reference', () => {
        const input = 'asdf/qwer#444 ';
        vm.onInput({ untouchedRawReferences: [input.trim()], touchedReference: input });

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual('asdf/qwer#444');
      });

      it('fill in with issue link', () => {
        const link = 'http://localhost:3000/foo/bar/issues/111';
        const input = `${link} `;
        vm.onInput({ untouchedRawReferences: [input.trim()], touchedReference: input });

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual(link);
      });

      it('fill in with multiple references', () => {
        const input = 'asdf/qwer#444 #12 ';
        vm.onInput({ untouchedRawReferences: input.trim().split(/\s/), touchedReference: 2 });

        expect(vm.state.pendingReferences.length).toEqual(2);
        expect(vm.state.pendingReferences[0]).toEqual('asdf/qwer#444');
        expect(vm.state.pendingReferences[1]).toEqual('#12');
      });

      it('fill in with some invalid things', () => {
        const input = 'something random ';
        vm.onInput({ untouchedRawReferences: input.trim().split(/\s/), touchedReference: 2 });

        expect(vm.state.pendingReferences.length).toEqual(2);
        expect(vm.state.pendingReferences[0]).toEqual('something');
        expect(vm.state.pendingReferences[1]).toEqual('random');
      });
    });

    describe('onBlur', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();

        spyOn(vm, 'processAllReferences');
      });

      it('add any references to pending when blurring', () => {
        const input = '#123';

        vm.onBlur(input);

        expect(vm.processAllReferences).toHaveBeenCalledWith(input);
      });
    });

    describe('processAllReferences', () => {
      beforeEach(() => {
        vm = new RelatedIssuesRoot({
          propsData: defaultProps,
        }).$mount();
      });

      it('add valid reference to pending', () => {
        const input = '#123';
        vm.processAllReferences(input);

        expect(vm.state.pendingReferences.length).toEqual(1);
        expect(vm.state.pendingReferences[0]).toEqual('#123');
      });

      it('add any valid references to pending', () => {
        const input = 'asdf #123';
        vm.processAllReferences(input);

        expect(vm.state.pendingReferences.length).toEqual(2);
        expect(vm.state.pendingReferences[0]).toEqual('asdf');
        expect(vm.state.pendingReferences[1]).toEqual('#123');
      });
    });
  });
});
