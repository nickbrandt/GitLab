/* global ListLabel */
/* global ListIssue */

import Vue from 'vue';
import _ from 'underscore';

import '~/vue_shared/models/label';
import '~/vue_shared/models/assignee';
import '~/boards/models/issue';
import '~/boards/models/list';
import IssueCardInner from '~/boards/components/issue_card_inner.vue';
import { listObj } from 'spec/boards/mock_data';

describe('Issue card component', () => {
  const label1 = new ListLabel({
    id: 3,
    title: 'testing 123',
    color: 'blue',
    text_color: 'white',
    description: 'test',
  });
  let component;
  let issue;
  let list;

  beforeEach(() => {
    setFixtures('<div class="test-container"></div>');

    list = listObj;
    issue = new ListIssue({
      title: 'Testing',
      id: 1,
      iid: 1,
      confidential: false,
      labels: [list.label],
      assignees: [],
      reference_path: '#1',
      real_path: '/test/1',
    });

    component = new Vue({
      el: document.querySelector('.test-container'),
      components: {
        'issue-card': IssueCardInner,
      },
      data() {
        return {
          list,
          issue,
          issueLinkBase: '/test',
          rootPath: '/',
          groupId: null,
        };
      },
      template: `
        <issue-card
          :issue="issue"
          :list="list"
          :group-id="groupId"
          :issue-link-base="issueLinkBase"
          :root-path="rootPath"></issue-card>
      `,
    });
  });

  describe('labels', () => {
    beforeEach(done => {
      component.issue.addLabel(label1);

      Vue.nextTick(() => done());
    });

    it('shows group labels on group boards', done => {
      component.issue.addLabel(
        new ListLabel({
          id: _.random(10000),
          title: 'Group label',
          type: 'GroupLabel',
        }),
      );
      component.groupId = 1;

      Vue.nextTick()
        .then(() => {
          expect(component.$el.querySelectorAll('.badge').length).toBe(3);

          expect(component.$el.textContent).toContain('Group label');

          done();
        })
        .catch(done.fail);
    });

    it('shows project labels on group boards', done => {
      component.issue.addLabel(
        new ListLabel({
          id: 123,
          title: 'Project label',
          type: 'ProjectLabel',
        }),
      );
      component.groupId = 1;

      Vue.nextTick()
        .then(() => {
          expect(component.$el.querySelectorAll('.badge').length).toBe(3);

          expect(component.$el.textContent).toContain('Project label');

          done();
        })
        .catch(done.fail);
    });
  });
});
