import { FOUR_MINUTES_IN_MS } from '~/ci/constants';
import { getIncreasedPollInterval } from '~/ci/utils/polling_utils';

describe('Polling utils', () => {
  describe('interval under max limit', () => {
    it('increases the interval', () => {
      expect(getIncreasedPollInterval(1000)).toEqual(1000 * 1.2);
      expect(getIncreasedPollInterval(2000)).toEqual(2000 * 1.2);
      expect(getIncreasedPollInterval(10000)).toEqual(10000 * 1.2);
      expect(getIncreasedPollInterval(200000)).toEqual(200000 * 1.2);
    });
  });

  describe('interval over max limit', () => {
    it('returns max interval value', () => {
      expect(getIncreasedPollInterval(300000)).toEqual(FOUR_MINUTES_IN_MS);
      expect(getIncreasedPollInterval(400000)).toEqual(FOUR_MINUTES_IN_MS);
      expect(getIncreasedPollInterval(500000)).toEqual(FOUR_MINUTES_IN_MS);
      expect(getIncreasedPollInterval(600000)).toEqual(FOUR_MINUTES_IN_MS);
    });
  });
});
