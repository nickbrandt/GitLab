import Vue from 'vue';
import WeightSelect from 'ee/boards/components/weight_select.vue';
import IssuableContext from '~/issuable_context';

let vm;
let board;

const expectedDropdownValues = {
  anyWeight: 'Any',
  noWeight: 'None',
};

// see ee/app/views/shared/boards/_switcher.html.haml
const weights = ['Any', 'None', 0, 1, 2, 3];

function getSelectedText() {
  return vm.$el.querySelector('.value').innerText.trim();
}

function activeDropdownItem() {
  return vm.$el.querySelector('.is-active').innerText.trim();
}

function findDropdownItem(text) {
  return Array.from(vm.$el.querySelectorAll('li a')).find(({ innerText }) => innerText === text);
}

describe('WeightSelect', () => {
  beforeEach(done => {
    setFixtures('<div class="test-container"></div>');

    board = {
      weight: -1,
      labels: [],
    };

    // eslint-disable-next-line no-new
    new IssuableContext();

    const Component = Vue.extend(WeightSelect);
    vm = new Component({
      propsData: {
        board,
        canEdit: true,
        weights,
      },
    }).$mount('.test-container');

    Vue.nextTick(done);
  });

  describe('selected value', () => {
    it('defaults to Any Weight', () => {
      expect(getSelectedText()).toBe('Any Weight');
    });

    it('displays Any Weight for null', done => {
      vm.value = null;
      Vue.nextTick(() => {
        expect(getSelectedText()).toEqual('Any Weight');
        done();
      });
    });

    it('displays No Weight for -1', done => {
      vm.value = -1;
      Vue.nextTick(() => {
        expect(getSelectedText()).toEqual('No Weight');
        done();
      });
    });

    it('displays weight for 0', done => {
      vm.value = 0;
      Vue.nextTick(() => {
        expect(getSelectedText()).toEqual('0');
        done();
      });
    });

    it('displays weight for 1', done => {
      vm.value = 1;
      Vue.nextTick(() => {
        expect(getSelectedText()).toEqual('1');
        done();
      });
    });
  });

  describe('active item in dropdown', () => {
    it('defaults to Any Weight', done => {
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual(expectedDropdownValues.anyWeight);
        done();
      });
    });

    it('shows No Weight', done => {
      vm.value = -1;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual(expectedDropdownValues.noWeight);
        done();
      });
    });

    it('shows correct weight', done => {
      vm.value = 1;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('1');
        done();
      });
    });
  });

  describe('changing weight', () => {
    it('sets value', done => {
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        findDropdownItem('2').click();
      });

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual('2');
        expect(board.weight).toEqual(2);
        done();
      });
    });

    it('sets Any Weight', done => {
      vm.value = 2;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        findDropdownItem('Any').click();
      });

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual(expectedDropdownValues.anyWeight);
        expect(board.weight).toEqual(null);
        done();
      });
    });

    it('sets Any Weight if it is already selected', done => {
      vm.value = null;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        findDropdownItem('Any').click();
      });

      setTimeout(() => {
        expect(board.weight).toEqual(null);
        done();
      });
    });

    it('sets No Weight', done => {
      vm.value = 2;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        findDropdownItem('None').click();
      });

      setTimeout(() => {
        expect(activeDropdownItem()).toEqual(expectedDropdownValues.noWeight);
        expect(board.weight).toEqual(-1);
        done();
      });
    });

    it('sets No Weight if it is already selected', done => {
      vm.value = -1;
      vm.$el.querySelector('.edit-link').click();

      setTimeout(() => {
        findDropdownItem('None').click();
      });

      setTimeout(() => {
        expect(board.weight).toEqual(-1);
        done();
      });
    });
  });
});
