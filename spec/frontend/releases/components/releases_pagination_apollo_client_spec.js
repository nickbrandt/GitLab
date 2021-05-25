import { GlKeysetPagination } from '@gitlab/ui';
import { mountExtended } from 'helpers/vue_test_utils_helper';
import { historyPushState } from '~/lib/utils/common_utils';
import ReleasesPaginationApolloClient from '~/releases/components/releases_pagination_apollo_client.vue';

jest.mock('~/lib/utils/common_utils', () => ({
  ...jest.requireActual('~/lib/utils/common_utils'),
  historyPushState: jest.fn(),
}));

describe('releases_pagination_apollo_client.vue', () => {
  const startCursor = 'startCursor';
  const endCursor = 'endCursor';
  let wrapper;
  let onPrev;
  let onNext;

  const createComponent = (pageInfo) => {
    onPrev = jest.fn();
    onNext = jest.fn();

    wrapper = mountExtended(ReleasesPaginationApolloClient, {
      propsData: {
        pageInfo,
      },
      listeners: {
        prev: onPrev,
        next: onNext,
      },
    });
  };

  afterEach(() => {
    wrapper.destroy();
  });

  const singlePageInfo = {
    hasPreviousPage: false,
    hasNextPage: false,
    startCursor,
    endCursor,
  };

  const onlyNextPageInfo = {
    hasPreviousPage: false,
    hasNextPage: true,
    startCursor,
    endCursor,
  };

  const onlyPrevPageInfo = {
    hasPreviousPage: true,
    hasNextPage: false,
    startCursor,
    endCursor,
  };

  const prevAndNextPageInfo = {
    hasPreviousPage: true,
    hasNextPage: true,
    startCursor,
    endCursor,
  };

  const findGlKeysetPagination = () => wrapper.findComponent(GlKeysetPagination);
  const findPrevButton = () => wrapper.findByTestId('prevButton');
  const findNextButton = () => wrapper.findByTestId('nextButton');

  describe.each`
    description                                             | pageInfo               | paginationRendered | prevEnabled | nextEnabled
    ${'when there is only one page of results'}             | ${singlePageInfo}      | ${false}           | ${'N/A'}    | ${'N/A'}
    ${'when there is a next page, but not a previous page'} | ${onlyNextPageInfo}    | ${true}            | ${false}    | ${true}
    ${'when there is a previous page, but not a next page'} | ${onlyPrevPageInfo}    | ${true}            | ${true}     | ${false}
    ${'when there is both a previous and next page'}        | ${prevAndNextPageInfo} | ${true}            | ${true}     | ${true}
  `(
    'component states',
    ({ description, pageInfo, paginationRendered, prevEnabled, nextEnabled }) => {
      describe(description, () => {
        beforeEach(() => {
          createComponent(pageInfo);
        });

        it(`does ${paginationRendered ? '' : 'not '}render a GlKeysetPagination`, () => {
          expect(findGlKeysetPagination().exists()).toBe(paginationRendered);
        });

        // The remaining tests don't apply if the GlKeysetPagination component is not rendered
        if (!paginationRendered) {
          return;
        }

        it(`renders the "Prev" button as ${prevEnabled ? 'enabled' : 'disabled'}`, () => {
          expect(findPrevButton().attributes().disabled).toBe(prevEnabled ? undefined : 'disabled');
        });

        it(`renders the "Next" button as ${nextEnabled ? 'enabled' : 'disabled'}`, () => {
          expect(findNextButton().attributes().disabled).toBe(nextEnabled ? undefined : 'disabled');
        });
      });
    },
  );

  describe('button behavior', () => {
    beforeEach(() => {
      createComponent(prevAndNextPageInfo);
    });

    describe('next button behavior', () => {
      beforeEach(() => {
        findNextButton().trigger('click');
      });

      it('emits an "next" event with the "after" cursor', () => {
        expect(onNext.mock.calls).toEqual([[endCursor]]);
      });

      it('calls historyPushState with the new URL', () => {
        expect(historyPushState.mock.calls).toEqual([
          [expect.stringContaining(`?after=${endCursor}`)],
        ]);
      });
    });

    describe('prev button behavior', () => {
      beforeEach(() => {
        findPrevButton().trigger('click');
      });

      it('emits an "prev" event with the "before" cursor', () => {
        expect(onPrev.mock.calls).toEqual([[startCursor]]);
      });

      it('calls historyPushState with the new URL', () => {
        expect(historyPushState.mock.calls).toEqual([
          [expect.stringContaining(`?before=${startCursor}`)],
        ]);
      });
    });
  });
});
