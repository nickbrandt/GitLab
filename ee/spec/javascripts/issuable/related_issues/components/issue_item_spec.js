import Vue from 'vue';
import issueItem from 'ee/related_issues/components/issue_item.vue';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { defaultMilestone, defaultAssignees } from '../mock_data';

describe('issueItem', () => {
  let vm;
  const props = {
    idKey: 1,
    displayReference: 'gitlab-org/gitlab-test#1',
    pathIdSeparator: '#',
    path: `${gl.TEST_HOST}/path`,
    title: 'title',
    confidential: true,
    dueDate: '1990-12-31',
    weight: 10,
    createdAt: '2018-12-01T00:00:00.00Z',
    milestone: defaultMilestone,
    assignees: defaultAssignees,
    eventNamespace: 'relatedIssue',
  };

  beforeEach(() => {
    const IssueItem = Vue.extend(issueItem);
    vm = mountComponent(IssueItem, props);
  });

  it('contains issuable-info-container class when canReorder is false', () => {
    expect(vm.canReorder).toEqual(false);
    expect(vm.$el.querySelector('.issuable-info-container')).toBeNull();
  });

  it('does not render token state', () => {
    expect(vm.$el.querySelector('.text-secondary svg')).toBeNull();
  });

  it('does not render remove button', () => {
    expect(vm.$refs.removeButton).toBeUndefined();
  });

  describe('token title', () => {
    it('links to computedPath', () => {
      expect(vm.$el.querySelector('.item-title a').href).toEqual(props.path);
    });

    it('renders confidential icon', () => {
      expect(
        vm.$el.querySelector('.item-title svg.confidential-icon use').getAttribute('xlink:href'),
      ).toContain('eye-slash');
    });

    it('renders title', () => {
      expect(vm.$el.querySelector('.item-title a').innerText.trim()).toEqual(props.title);
    });
  });

  describe('token state', () => {
    let tokenState;

    beforeEach(done => {
      vm.state = 'opened';
      Vue.nextTick(() => {
        tokenState = vm.$el.querySelector('.item-meta svg');
        done();
      });
    });

    it('renders if hasState', () => {
      expect(tokenState).toBeDefined();
    });

    it('renders state title', () => {
      const stateTitle = tokenState.getAttribute('data-original-title').trim();

      expect(stateTitle).toContain('<span class="bold">Opened</span>');
      expect(stateTitle).toContain(
        '<span class="text-tertiary">Dec 1, 2018 12:00am GMT+0000</span>',
      );
    });

    it('renders aria label', () => {
      expect(tokenState.getAttribute('aria-label')).toEqual('opened');
    });

    it('renders open icon when open state', () => {
      expect(tokenState.classList.contains('issue-token-state-icon-open')).toEqual(true);
    });

    it('renders close icon when close state', done => {
      vm.state = 'closed';
      vm.closedAt = '2018-12-01T00:00:00.00Z';

      Vue.nextTick(() => {
        expect(tokenState.classList.contains('issue-token-state-icon-closed')).toEqual(true);
        done();
      });
    });
  });

  describe('token metadata', () => {
    let tokenMetadata;

    beforeEach(done => {
      Vue.nextTick(() => {
        tokenMetadata = vm.$el.querySelector('.item-meta');
        done();
      });
    });

    it('renders item path and ID', () => {
      const pathAndID = tokenMetadata.querySelector('.item-path-id').innerText.trim();

      expect(pathAndID).toContain('gitlab-org/gitlab-test');
      expect(pathAndID).toContain('#1');
    });

    it('renders milestone icon and name', () => {
      const milestoneIconEl = tokenMetadata.querySelector('.item-milestone svg use');
      const milestoneTitle = tokenMetadata.querySelector('.item-milestone .milestone-title');

      expect(milestoneIconEl.getAttribute('xlink:href')).toContain('clock');
      expect(milestoneTitle.innerText.trim()).toContain('Milestone title');
    });

    it('renders date icon and due date', () => {
      const dueDateIconEl = tokenMetadata.querySelector('.item-due-date svg use');
      const dueDateEl = tokenMetadata.querySelector('.item-due-date time');

      expect(dueDateIconEl.getAttribute('xlink:href')).toContain('calendar');
      expect(dueDateEl.innerText.trim()).toContain('Dec 31');
    });

    it('renders weight icon and value', () => {
      const dueDateIconEl = tokenMetadata.querySelector('.item-weight svg use');
      const dueDateEl = tokenMetadata.querySelector('.item-weight span');

      expect(dueDateIconEl.getAttribute('xlink:href')).toContain('weight');
      expect(dueDateEl.innerText.trim()).toContain('10');
    });
  });

  describe('token assignees', () => {
    it('renders assignees avatars', () => {
      const assigneesEl = vm.$el.querySelector('.item-assignees');

      expect(assigneesEl.querySelectorAll('.user-avatar-link').length).toBe(2);
      expect(assigneesEl.querySelector('.avatar-counter').innerText.trim()).toContain('+2');
    });
  });

  describe('remove button', () => {
    let removeBtn;

    beforeEach(done => {
      vm.canRemove = true;
      Vue.nextTick(() => {
        removeBtn = vm.$refs.removeButton;
        done();
      });
    });

    it('renders if canRemove', () => {
      expect(removeBtn).toBeDefined();
    });

    it('renders disabled button when removeDisabled', done => {
      vm.removeDisabled = true;
      Vue.nextTick(() => {
        expect(removeBtn.hasAttribute('disabled')).toEqual(true);
        done();
      });
    });

    it('triggers onRemoveRequest when clicked', () => {
      spyOn(vm, '$emit');
      removeBtn.click();

      expect(vm.$emit).toHaveBeenCalledWith('relatedIssueRemoveRequest', props.idKey);
    });
  });
});
