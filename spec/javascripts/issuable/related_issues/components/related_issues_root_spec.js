import Vue from 'vue';
import RelatedIssuesRoot from '~/issuable/related_issues/components/related_issues_root.vue';

const defaultProps = {
  endpoint: '/foo/bar/issues/1/related_issues',
  currentNamespacePath: 'foo',
  currentProjectPath: 'bar',
};

const createComponent = (propsData = {}) => {
  const Component = Vue.extend(RelatedIssuesRoot);

  return new Component({
    el: document.createElement('div'),
    propsData,
  });
};

const issuable1 = {
  reference: 'foo/bar#123',
  title: 'issue1',
  path: '/foo/bar/issues/123',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/123/related_issues/1',
};

const issuable2 = {
  reference: 'foo/bar#124',
  title: 'issue2',
  path: '/foo/bar/issues/124',
  state: 'opened',
  destroy_relation_path: '/foo/bar/issues/124/related_issues/2',
};

describe('RelatedIssuesRoot', () => {
  let vm;
  afterEach(() => {
    if (vm) {
      vm.$destroy();
    }
  });

  describe('methods', () => {
    describe('onRelatedIssueRemoveRequest', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.addToIssueMap(issuable1.reference, issuable1);
        vm.store.setRelatedIssues([issuable1.reference]);
      });

      it('remove related issue and succeeds', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 200,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1.reference);

        setTimeout(() => {
          expect(vm.computedRelatedIssues).toEqual([]);

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });

      it('remove related issue, fails, and restores to related issues', (done) => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 422,
          }));
        };
        Vue.http.interceptors.push(interceptor);

        vm.onRelatedIssueRemoveRequest(issuable1.reference);

        setTimeout(() => {
          expect(vm.computedRelatedIssues.length).toEqual(1);
          expect(vm.computedRelatedIssues[0].reference).toEqual('#123');
          expect(vm.requestError).toBeDefined();

          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);

          done();
        });
      });
    });

    describe('onShowAddRelatedIssuesForm', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('show add related issues form', () => {
        vm.onShowAddRelatedIssuesForm();

        expect(vm.isAddRelatedIssuesFormVisible).toEqual(true);
      });
    });

    describe('onAddIssuableFormInput', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('fill in issue number reference and adds to pending related issues', () => {
        const input = '#123 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });

      it('fill in with full reference', () => {
        const input = 'asdf/qwer#444 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('asdf/qwer#444');
      });

      it('fill in with multiple references', () => {
        const input = 'asdf/qwer#444 #12 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(2);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('asdf/qwer#444');
        expect(vm.computedPendingRelatedIssues[1].reference).toEqual('#12');
      });

      it('fill in with some invalid things', () => {
        const input = 'something random stuff here ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });

      it('fill in invalid and some legit references', () => {
        const input = 'something random #123 ';
        vm.onAddIssuableFormInput(input, input.length);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });

      it('keep reference piece in input while we are touching it', () => {
        const input = 'a #123 b';
        vm.onAddIssuableFormInput(input, 3);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('onAddIssuableFormBlur', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('add valid reference to pending when blurring', () => {
        const input = '#123';
        vm.onAddIssuableFormBlur(input);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });

      it('add any valid references to pending when blurring', () => {
        const input = 'asdf #123';
        vm.onAddIssuableFormBlur(input);

        expect(vm.computedPendingRelatedIssues.length).toEqual(1);
        expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
      });
    });

    describe('onAddIssuableFormIssuableRemoveRequest', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.addToIssueMap(issuable1.reference, issuable1);
        vm.store.setPendingRelatedIssues([issuable1.reference]);
      });

      it('remove pending related issue', () => {
        vm.onAddIssuableFormIssuableRemoveRequest(issuable1.reference);

        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
      });
    });

    describe('onAddIssuableFormSubmit', () => {
      describe('when service.addRelatedIssues is succeeding', () => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 200,
          }));
        };

        beforeEach(() => {
          vm = createComponent(defaultProps);
          vm.store.addToIssueMap(issuable1.reference, issuable1);
          vm.store.addToIssueMap(issuable2.reference, issuable2);

          Vue.http.interceptors.push(interceptor);
        });

        afterEach(() => {
          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
        });

        it('submit pending issues as related issues', (done) => {
          vm.store.setPendingRelatedIssues([issuable1.reference]);
          vm.onAddIssuableFormSubmit();

          setTimeout(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(0);
            expect(vm.computedRelatedIssues.length).toEqual(1);
            expect(vm.computedRelatedIssues[0].reference).toEqual('#123');

            done();
          });
        });

        it('submit multiple pending issues as related issues', (done) => {
          vm.store.setPendingRelatedIssues([issuable1.reference, issuable2.reference]);
          vm.onAddIssuableFormSubmit();

          setTimeout(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(0);
            expect(vm.computedRelatedIssues.length).toEqual(2);
            expect(vm.computedRelatedIssues[0].reference).toEqual('#123');
            expect(vm.computedRelatedIssues[1].reference).toEqual('#124');

            done();
          });
        });
      });

      describe('when service.addRelatedIssues fails', () => {
        const interceptor = (request, next) => {
          next(request.respondWith(JSON.stringify({}), {
            status: 422,
          }));
        };

        beforeEach(() => {
          vm = createComponent(defaultProps);
          vm.store.addToIssueMap(issuable1.reference, issuable1);
          vm.store.addToIssueMap(issuable2.reference, issuable2);

          Vue.http.interceptors.push(interceptor);
        });

        afterEach(() => {
          Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
        });

        it('submit pending issues as related issues fails and restores to pending related issues', (done) => {
          vm.store.setPendingRelatedIssues([issuable1.reference]);
          vm.onAddIssuableFormSubmit();

          setTimeout(() => {
            expect(vm.computedPendingRelatedIssues.length).toEqual(1);
            expect(vm.computedPendingRelatedIssues[0].reference).toEqual('#123');
            expect(vm.computedRelatedIssues.length).toEqual(0);
            expect(vm.requestError).toBeDefined();

            done();
          });
        });
      });
    });

    describe('onAddIssuableFormCancel', () => {
      beforeEach(() => {
        vm = createComponent(defaultProps);
        vm.store.setIsAddRelatedIssuesFormVisible(true);
        vm.store.setAddRelatedIssuesFormInputValue('foo');
      });

      it('when canceling and hiding add issuable form', () => {
        vm.onAddIssuableFormCancel();

        expect(vm.isAddRelatedIssuesFormVisible).toEqual(false);
        expect(vm.computedPendingRelatedIssues.length).toEqual(0);
        expect(vm.addRelatedIssuesFormInputValue).toEqual('');
      });
    });

    describe('fetchRelatedIssues', () => {
      const interceptor = (request, next) => {
        next(request.respondWith(JSON.stringify([issuable1, issuable2]), {
          status: 200,
        }));
      };

      beforeEach(() => {
        vm = createComponent(defaultProps);

        Vue.http.interceptors.push(interceptor);
      });

      afterEach(() => {
        Vue.http.interceptors = _.without(Vue.http.interceptors, interceptor);
      });

      it('fetching related issues', (done) => {
        vm.fetchRelatedIssues();

        setTimeout(() => {
          expect(vm.issueMap).toEqual({
            [issuable1.reference]: issuable1,
            [issuable2.reference]: issuable2,
          });
          expect(vm.computedRelatedIssues.length).toEqual(2);
          expect(vm.computedRelatedIssues[0].reference).toEqual('#123');
          expect(vm.computedRelatedIssues[1].reference).toEqual('#124');

          done();
        });
      });
    });

    describe('processIssuableReferences', () => {
      const issuablePath = `${defaultProps.currentNamespacePath}/${defaultProps.currentProjectPath}`;
      beforeEach(() => {
        vm = createComponent(defaultProps);
      });

      it('process issue number reference', () => {
        const reference = '#123';
        const result = vm.processIssuableReferences([reference]);

        expect(result).toEqual({
          unprocessableReferences: [],
          fullReferences: [`${issuablePath}${reference}`],
        });
      });

      it('process multiple issue number references with some unprocecessable', () => {
        const rawReferences = '#123 abc #456'.split(/\s/);
        const result = vm.processIssuableReferences(rawReferences);

        expect(result).toEqual({
          unprocessableReferences: [
            'abc',
          ],
          fullReferences: [
            `${issuablePath}${rawReferences[0]}`,
            `${issuablePath}${rawReferences[2]}`,
          ],
        });
      });
    });
  });
});
