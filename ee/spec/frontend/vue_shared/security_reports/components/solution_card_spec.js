import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/solution_card.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { trimText } from 'spec/helpers/vue_component_helper';

describe('Solution Card', () => {
  const Component = Vue.extend(component);
  const solution = 'Upgrade to XYZ';
  const remediation = { summary: 'Update to 123', fixes: [], diff: 'SGVsbG8gR2l0TGFi' };
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('computed properties', () => {
    describe('solutionText', () => {
      it('takes the value of solution', () => {
        const props = { solution };
        vm = mountComponent(Component, props);

        expect(vm.solutionText).toEqual(solution);
      });

      it('takes the summary from a remediation', () => {
        const props = { remediation };
        vm = mountComponent(Component, props);

        expect(vm.solutionText).toEqual(remediation.summary);
      });

      it('takes the summary from a remediation, if both are defined', () => {
        const props = { remediation, solution };
        vm = mountComponent(Component, props);

        expect(vm.solutionText).toEqual(remediation.summary);
      });
    });

    describe('remediationDiff', () => {
      it('returns the base64 diff from a remediation', () => {
        const props = { remediation };
        vm = mountComponent(Component, props);

        expect(vm.remediationDiff).toEqual(remediation.diff);
      });
    });

    describe('hasDiff', () => {
      it('is false if only the solution is defined', () => {
        const props = { solution };
        vm = mountComponent(Component, props);

        expect(vm.hasDiff).toBe(false);
      });

      it('is false if remediation misses a diff', () => {
        const props = { remediation: { summary: 'XYZ' } };
        vm = mountComponent(Component, props);

        expect(vm.hasDiff).toBe(false);
      });

      it('is true if remediation has a diff', () => {
        const props = { remediation };
        vm = mountComponent(Component, props);

        expect(vm.hasDiff).toBe(true);
      });
    });

    describe('downloadUrl', () => {
      it('returns dataUrl for a remediation diff ', () => {
        const props = { remediation };
        vm = mountComponent(Component, props);

        expect(vm.downloadUrl).toBe('data:text/plain;base64,SGVsbG8gR2l0TGFi');
      });
    });
  });

  describe('rendering', () => {
    describe('with solution', () => {
      beforeEach(() => {
        const props = { solution };
        vm = mountComponent(Component, props);
      });

      it('renders the solution text and label', () => {
        expect(trimText(vm.$el.querySelector('.card-body').textContent)).toContain(
          `Solution: ${solution}`,
        );
      });

      it('does not render the card footer', () => {
        expect(vm.$el.querySelector('.card-footer')).toBeNull();
      });

      it('does not render the download link', () => {
        expect(vm.$el.querySelector('a')).toBeNull();
      });
    });

    describe('with remediation', () => {
      beforeEach(() => {
        const props = { remediation };
        vm = mountComponent(Component, props);
      });

      it('renders the solution text and label', () => {
        expect(trimText(vm.$el.querySelector('.card-body').textContent)).toContain(
          `Solution: ${remediation.summary}`,
        );
      });

      it('renders the card footer', () => {
        expect(vm.$el.querySelector('.card-footer')).not.toBeNull();
      });

      it('renders the download link', () => {
        const linkEl = vm.$el.querySelector('a');

        expect(linkEl).not.toBeNull();
        expect(linkEl.getAttribute('href')).toEqual(vm.downloadUrl);
        expect(linkEl.getAttribute('download')).toEqual('remediation.patch');
      });
    });
  });
});
