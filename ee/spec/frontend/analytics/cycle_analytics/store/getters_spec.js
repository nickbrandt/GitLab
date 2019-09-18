import * as getters from 'ee/analytics/cycle_analytics/store/getters';
import { allowedStages as stages } from '../mock_data';

let state = null;

describe('Cycle analytics getters', () => {
  describe('with default state', () => {
    beforeEach(() => {
      state = {
        stages: [],
        selectedStageName: null,
      };
    });

    afterEach(() => {
      state = null;
    });

    describe('currentStage', () => {
      it('will return null', () => {
        expect(getters.currentStage(state)).toEqual(null);
      });
    });

    describe('defaultStage', () => {
      it('will return null', () => {
        expect(getters.defaultStage(state)).toEqual(null);
      });
    });
  });

  describe('with a set of stages', () => {
    beforeEach(() => {
      state = {
        stages,
        selectedStageName: null,
      };
    });

    afterEach(() => {
      state = null;
    });

    describe('currentStage', () => {
      it('will return null', () => {
        expect(getters.currentStage(state)).toEqual(null);
      });
    });

    describe('defaultStage', () => {
      it('will return the first stage', () => {
        expect(getters.defaultStage(state)).toEqual(stages[0]);
      });
    });
  });

  describe('with a set of stages and a stage selected', () => {
    beforeEach(() => {
      state = {
        stages,
        selectedStageName: stages[2].name,
      };
    });

    afterEach(() => {
      state = null;
    });

    describe('currentStage', () => {
      it('will return null', () => {
        expect(getters.currentStage(state)).toEqual(stages[2]);
      });
    });
  });
});
