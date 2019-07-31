import Vue from 'vue';
import MockAdapater from 'axios-mock-adapter';
import axios from '~/lib/utils/axios_utils';
import MilestoneSelect from 'ee/boards/components/milestone_select.vue';
import IssuableContext from '~/issuable_context';
import { boardObj } from 'spec/boards/mock_data';

let vm;

function selectedText() {
  return vm.$el.querySelector('.value').innerText.trim();
}

function activeDropdownItem(index) {
  const items = vm.$el.querySelectorAll('.is-active');
  if (!items[index]) return '';
  return items[index].innerText.trim();
}

function findDropdownItem(text) {
  return Array.from(vm.$el.querySelectorAll('li a')).find(({ innerText }) => innerText === text);
}

const milestone = {
  id: 1,
  title: 'first milestone',
  name: 'first milestone',
};

const milestone2 = {
  id: 2,
  title: 'second milestone',
  name: 'second milestone',
};

describe('Milestone select component', () => {
  beforeEach(done => {
    setFixtures('<div class="test-container"></div>');

    // eslint-disable-next-line no-new
    new IssuableContext();

    const Component = Vue.extend(MilestoneSelect);
    vm = new Component({
      propsData: {
        board: { ...boardObj },
        milestonePath: '/test/issue-boards/milestones.json',
        canEdit: true,
      },
    }).$mount('.test-container');

    setTimeout(done);
  });

  describe('canEdit', () => {
    it('hides Edit button', done => {
      vm.canEdit = false;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.edit-link')).toBeFalsy();
        done();
      });
    });

    it('shows Edit button if true', done => {
      vm.canEdit = true;
      Vue.nextTick(() => {
        expect(vm.$el.querySelector('.edit-link')).toBeTruthy();
        done();
      });
    });
  });

  describe('selected value', () => {
    it('defaults to Any Milestone', () => {
      expect(selectedText()).toContain('Any Milestone');
    });

    it('shows No Milestone', done => {
      vm.board.milestone_id = -1;
      Vue.nextTick(() => {
        expect(selectedText()).toContain('No Milestone');
        done();
      });
    });

    it('shows selected milestone title', done => {
      vm.board.milestone_id = 20;
      vm.board.milestone = {
        id: 20,
        title: 'Selected milestone',
      };
      Vue.nextTick(() => {
        expect(selectedText()).toContain('Selected milestone');
        done();
      });
    });

    describe('clicking dropdown items', () => {
      let mock;

      beforeEach(() => {
        mock = new MockAdapater(axios);
        mock.onGet('/test/issue-boards/milestones.json').reply(200, [milestone, milestone2]);
      });

      afterEach(() => {
        mock.restore();
      });

      it('sets Any Milestone', done => {
        vm.board.milestone_id = -1;
        vm.$el.querySelector('.edit-link').click();

        setTimeout(() => {
          findDropdownItem('Any Milestone').click();
        });

        setTimeout(() => {
          expect(activeDropdownItem(0)).toEqual('Any Milestone');
          expect(selectedText()).toEqual('Any Milestone');
          done();
        });
      });

      it('sets No Milestone', done => {
        vm.$el.querySelector('.edit-link').click();

        setTimeout(() => {
          findDropdownItem('No Milestone').click();
        });

        setTimeout(() => {
          expect(activeDropdownItem(0)).toEqual('No Milestone');
          expect(selectedText()).toEqual('No Milestone');
          done();
        });
      });

      it('sets milestone', done => {
        vm.$el.querySelector('.edit-link').click();

        setTimeout(() => {
          findDropdownItem('first milestone').click();
        });

        setTimeout(() => {
          expect(activeDropdownItem(0)).toEqual('first milestone');
          expect(selectedText()).toEqual('first milestone');
          expect(vm.board.milestone).toEqual(milestone);
          done();
        });
      });
    });
  });
});
