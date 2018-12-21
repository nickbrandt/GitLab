import Vue from 'vue';
import BoardService from 'ee/boards/services/board_service';
import BoardsSelector from 'ee/boards/components/boards_selector.vue';
import setTimeoutPromiseHelper from 'spec/helpers/set_timeout_promise_helper';
import mountComponent from 'spec/helpers/vue_mount_component_helper';
import { TEST_HOST } from 'spec/test_constants';

const throttleDuration = 1;

function waitForScroll() {
  return Vue.nextTick()
    .then(() => setTimeoutPromiseHelper(throttleDuration))
    .then(() => Vue.nextTick());
}

describe('BoardsSelector', () => {
  let vm;
  let scrollContainer;
  let scrollFade;
  let boardServiceResponse;
  const boards = new Array(20).fill().map((board, id) => {
    const name = `board${id}`;

    return {
      id,
      name,
    };
  });

  beforeEach(done => {
    setFixtures('<div class="js-boards-selector"></div>');
    window.gl = window.gl || {};

    window.gl.boardService = new BoardService({
      boardsEndpoint: '',
      listsEndpoint: '',
      bulkUpdatePath: '',
      boardId: '',
    });

    boardServiceResponse = Promise.resolve({
      data: boards,
    });

    spyOn(BoardService.prototype, 'allBoards').and.returnValue(boardServiceResponse);

    const Component = Vue.extend(BoardsSelector);
    vm = mountComponent(
      Component,
      {
        throttleDuration,
        currentBoard: {
          id: 1,
          name: 'Development',
          milestone_id: null,
          weight: null,
          assignee_id: null,
          labels: [],
        },
        milestonePath: `${TEST_HOST}/milestone/path`,
        boardBaseUrl: `${TEST_HOST}/board/base/url`,
        hasMissingBoards: false,
        canAdminBoard: true,
        multipleIssueBoardsAvailable: true,
        labelsPath: `${TEST_HOST}/labels/path`,
        projectId: 42,
        groupId: 19,
        scopedIssueBoardFeatureEnabled: true,
        weights: [],
      },
      document.querySelector('.js-boards-selector'),
    );

    vm.$el.querySelector('.js-dropdown-toggle').click();

    boardServiceResponse
      .then(() => vm.$nextTick())
      .then(() => {
        scrollFade = vm.$el.querySelector('.js-scroll-fade');
        scrollContainer = scrollFade.querySelector('.js-dropdown-list');

        scrollContainer.style.maxHeight = '100px';
        scrollContainer.style.overflowY = 'scroll';
      })
      .then(done)
      .catch(done.fail);
  });

  afterEach(() => {
    vm.$destroy();
    window.gl.boardService = undefined;
  });

  it('shows the scroll fade if isScrolledUp', done => {
    scrollContainer.scrollTop = 0;

    waitForScroll()
      .then(() => {
        expect(scrollFade.classList.contains('fade-out')).toEqual(false);
      })
      .then(done)
      .catch(done.fail);
  });

  it('hides the scroll fade if not isScrolledUp', done => {
    scrollContainer.scrollTop = scrollContainer.scrollHeight;

    waitForScroll()
      .then(() => {
        expect(scrollFade.classList.contains('fade-out')).toEqual(true);
      })
      .then(done)
      .catch(done.fail);
  });

  describe('filtering', () => {
    const fillSearchBox = filterTerm => {
      const { searchBox } = vm.$refs;
      const searchBoxInput = searchBox.$el.querySelector('input');
      searchBoxInput.value = filterTerm;
      searchBoxInput.dispatchEvent(new Event('input'));
    };

    it('shows all boards without filtering', () => {
      const dropdownItemCount = vm.$el.querySelectorAll('.js-dropdown-item');

      expect(dropdownItemCount.length).toBe(boards.length);
    });

    it('shows only matching boards when filtering', done => {
      const filterTerm = 'board1';
      const expectedCount = boards.filter(board => board.name.includes(filterTerm)).length;

      fillSearchBox(filterTerm);

      vm.$nextTick()
        .then(() => {
          const dropdownItems = vm.$el.querySelectorAll('.js-dropdown-item');

          expect(dropdownItems.length).toBe(expectedCount);
        })
        .then(done)
        .catch(done.fail);
    });

    it('shows message if there are no matching boards', done => {
      fillSearchBox('does not exist');

      vm.$nextTick()
        .then(() => {
          const dropdownItems = vm.$el.querySelectorAll('.js-dropdown-item');

          expect(dropdownItems.length).toBe(0);
          expect(vm.$el).toContainText('No matching boards found');
        })
        .then(done)
        .catch(done.fail);
    });
  });
});
