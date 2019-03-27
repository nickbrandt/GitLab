import Vue from 'vue';
import component from 'ee/vue_shared/security_reports/components/modal.vue';
import createState from 'ee/vue_shared/security_reports/store/state';
import mountComponent from 'spec/helpers/vue_mount_component_helper';

describe('Security Reports modal', () => {
  const Component = Vue.extend(component);
  let vm;

  afterEach(() => {
    vm.$destroy();
  });

  describe('with permissions', () => {
    describe('with dismissed issue', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          canCreateFeedbackPermission: true,
        };
        props.modal.vulnerability.isDismissed = true;
        props.modal.vulnerability.dismissalFeedback = {
          author: { username: 'jsmith' },
          pipeline: { id: '123' },
        };
        vm = mountComponent(Component, props);
      });

      it('renders dismissal author and associated pipeline', () => {
        expect(vm.$el.textContent.trim()).toContain('@jsmith');
        expect(vm.$el.textContent.trim()).toContain('#123');
      });

      it('renders button to undo dismiss', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual('Undo dismiss');
      });

      it('emits revertDismissIssue when undo dismiss button is clicked', () => {
        spyOn(vm, '$emit');

        const button = vm.$el.querySelector('.js-dismiss-btn');
        button.click();

        expect(vm.$emit).toHaveBeenCalledWith('revertDismissIssue');
      });
    });

    describe('with not dismissed issue', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          canCreateFeedbackPermission: true,
        };
        vm = mountComponent(Component, props);
      });

      it('renders button to dismiss issue', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn').textContent.trim()).toEqual(
          'Dismiss vulnerability',
        );
      });

      it('does not render create issue button', () => {
        expect(vm.$el.querySelector('.js-create-issue-btn')).toBe(null);
      });

      it('renders the dismiss button', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn')).not.toBe(null);
      });

      it('renders the footer', () => {
        expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(false);
      });

      it('emits dismissIssue when dismiss issue button is clicked', () => {
        spyOn(vm, '$emit');

        const button = vm.$el.querySelector('.js-dismiss-btn');
        button.click();

        expect(vm.$emit).toHaveBeenCalledWith('dismissIssue');
      });
    });

    describe('with create issue', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          canCreateIssuePermission: true,
        };
        vm = mountComponent(Component, props);
      });

      it('does not render dismiss button', () => {
        expect(vm.$el.querySelector('.js-dismiss-btn')).toBe(null);
      });

      it('renders create issue button', () => {
        expect(vm.$el.querySelector('.js-action-button')).not.toBe(null);
      });

      it('renders the footer', () => {
        expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(false);
      });

      it('emits createIssue when create issue button is clicked', () => {
        spyOn(vm, '$emit');

        const button = vm.$el.querySelector('.js-action-button');
        button.click();

        expect(vm.$emit).toHaveBeenCalledWith('createNewIssue');
      });
    });

    describe('data', () => {
      beforeEach(() => {
        const props = {
          modal: createState().modal,
          vulnerabilityFeedbackHelpPath: 'feedbacksHelpPath',
        };
        props.modal.title = 'Arbitrary file existence disclosure in Action Pack';
        vm = mountComponent(Component, props);
      });

      it('renders title', () => {
        expect(vm.$el.textContent).toContain('Arbitrary file existence disclosure in Action Pack');
      });

      it('renders help link', () => {
        expect(
          vm.$el.querySelector('.js-link-vulnerabilityFeedbackHelpPath').getAttribute('href'),
        ).toEqual('feedbacksHelpPath');
      });
    });
  });

  describe('without permissions', () => {
    beforeEach(() => {
      const props = {
        modal: createState().modal,
      };
      vm = mountComponent(Component, props);
    });

    it('does not render action buttons', () => {
      expect(vm.$el.querySelector('.js-dismiss-btn')).toBe(null);
      expect(vm.$el.querySelector('.js-create-issue-btn')).toBe(null);
    });

    it('does not display the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toEqual(true);
    });
  });

  describe('with a resolved issue', () => {
    beforeEach(() => {
      const props = {
        modal: createState().modal,
      };
      props.modal.isResolved = true;
      vm = mountComponent(Component, props);
    });

    it('does not display the footer', () => {
      expect(vm.$el.classList.contains('modal-hide-footer')).toBeTruthy();
    });
  });

  describe('Vulnerability Details', () => {
    it('is rendered', () => {
      const props = {
        modal: createState().modal,
      };
      props.modal.data.namespace.value = 'foobar';
      vm = mountComponent(Component, props);

      const vulnerabilityDetails = vm.$el.querySelector('.js-vulnerability-details');

      expect(vulnerabilityDetails).not.toBeNull();
      expect(vulnerabilityDetails.textContent).toContain('foobar');
    });
  });

  describe('Solution Card', () => {
    it('is rendered if the vulnerability has a solution', () => {
      const props = {
        modal: createState().modal,
      };

      const solution = 'Upgrade to XYZ';
      props.modal.vulnerability.solution = solution;
      vm = mountComponent(Component, props);

      const solutionCard = vm.$el.querySelector('.js-solution-card');

      expect(solutionCard).not.toBeNull();
      expect(solutionCard.textContent).toContain(solution);
      expect(vm.$el.querySelector('hr')).toBeNull();
    });

    it('is rendered if the vulnerability has a remediation', () => {
      const props = {
        modal: createState().modal,
      };
      const summary = 'Upgrade to 123';
      props.modal.vulnerability.remediations = [{ summary }];
      vm = mountComponent(Component, props);

      const solutionCard = vm.$el.querySelector('.js-solution-card');

      expect(solutionCard).not.toBeNull();
      expect(solutionCard.textContent).toContain(summary);
      expect(vm.$el.querySelector('hr')).toBeNull();
    });

    it('is not rendered if the vulnerability has neither a remediation nor a solution but renders a HR instead.', () => {
      const props = {
        modal: createState().modal,
      };
      vm = mountComponent(Component, props);

      const solutionCard = vm.$el.querySelector('.js-solution-card');

      expect(solutionCard).toBeNull();
      expect(vm.$el.querySelector('hr')).not.toBeNull();
    });
  });
});
