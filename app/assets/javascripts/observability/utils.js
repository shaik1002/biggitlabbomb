import { isValidDate } from '~/lib/utils/datetime_utility';

import {
  CUSTOM_DATE_RANGE_OPTION,
  DATE_RANGE_QUERY_KEY,
  DATE_RANGE_START_QUERY_KEY,
  DATE_RANGE_END_QUERY_KEY,
  TIMESTAMP_QUERY_KEY,
} from './constants';

/**
 * Return the data range for the given time period
 * Accepted values are numbers followed by the unit 'm', 'h', 'd', e.g. '5m', '3h', '7d'
 *
 *  e.g. timePerdio: '5m'
 *      returns: { min: Date(_now - 5min_), max: Date(_now_) }
 *
 * @param {String} timePeriod The 'period' string
 * @returns {{max: Date, min: Date}|{}} where max, min are Date objects representing the period range
 *  It returns {} if the period filter does not represent any range (invalid range, etc)
 */
export const periodToDate = (timePeriod) => {
  const maxMs = Date.now();
  let minMs;
  const periodValue = parseInt(timePeriod.slice(0, -1), 10);
  if (Number.isNaN(periodValue) || periodValue <= 0) return {};

  const unit = timePeriod[timePeriod.length - 1];
  switch (unit) {
    case 'm':
      minMs = periodValue * 60 * 1000;
      break;
    case 'h':
      minMs = periodValue * 60 * 1000 * 60;
      break;
    case 'd':
      minMs = periodValue * 60 * 1000 * 60 * 24;
      break;
    default:
      return {};
  }
  return { min: new Date(maxMs - minMs), max: new Date(maxMs) };
};

/**
 * Validates the date range query parameters and returns an object with the validated date range.
 *
 * @param {string} dateRangeValue - The value of the date range query parameter.
 * @param {string} dateRangeStart - The value of the start date query parameter.
 * @param {string} dateRangeEnd - The value of the end date query parameter.
 * @returns {{value: string, startDate?: Date, endDate?: Date}} An object containing the validated date range.
 */

function validatedDateRangeQuery(dateRangeValue, dateRangeStart, dateRangeEnd) {
  const DEFAULT_TIME_RANGE = '1h';
  if (dateRangeValue === CUSTOM_DATE_RANGE_OPTION) {
    if (isValidDate(new Date(dateRangeStart)) && isValidDate(new Date(dateRangeEnd))) {
      return {
        value: dateRangeValue,
        startDate: new Date(dateRangeStart),
        endDate: new Date(dateRangeEnd),
      };
    }
    return {
      value: DEFAULT_TIME_RANGE,
    };
  }
  return {
    value: dateRangeValue ?? DEFAULT_TIME_RANGE,
  };
}

/**
 * Converts a query object containing date range parameters to a validated date filter object.
 *
 * @param {Object} queryObj - The query object containing date range parameters.
 * @param {string} queryObj[DATE_RANGE_QUERY_KEY] - The value of the date range query parameter.
 * @param {string} queryObj[DATE_RANGE_START_QUERY_KEY] - The value of the start date query parameter.
 * @param {string} queryObj[DATE_RANGE_END_QUERY_KEY] - The value of the end date query parameter.
 * @returns {{value: string, startDate?: Date, endDate?: Date}} An object containing the validated date range.
 */
export function queryToDateFilterObj(queryObj) {
  const {
    [DATE_RANGE_QUERY_KEY]: dateRangeValue,
    [DATE_RANGE_START_QUERY_KEY]: dateRangeStart,
    [DATE_RANGE_END_QUERY_KEY]: dateRangeEnd,
    [TIMESTAMP_QUERY_KEY]: timestamp,
  } = queryObj;

  if (timestamp) {
    return {
      value: CUSTOM_DATE_RANGE_OPTION,
      startDate: new Date(timestamp),
      endDate: new Date(timestamp),
      timestamp,
    };
  }

  return validatedDateRangeQuery(dateRangeValue, dateRangeStart, dateRangeEnd);
}

/**
 * Converts a date filter object to a query object with date range parameters.
 *
 * @param {Object} dateFilter - The date filter object.
 * @param {string} dateFilter.value - The value of the date range.
 * @param {Date} [dateFilter.startDate] - The start date of the date range.
 * @param {Date} [dateFilter.endDate] - The end date of the date range.
 * @returns {Object} An object containing the date range query parameters.
 */
export function dateFilterObjToQuery(dateFilter = {}) {
  return {
    [DATE_RANGE_QUERY_KEY]: dateFilter.value,
    ...(dateFilter.value === CUSTOM_DATE_RANGE_OPTION
      ? {
          [DATE_RANGE_START_QUERY_KEY]: dateFilter.startDate?.toISOString(),
          [DATE_RANGE_END_QUERY_KEY]: dateFilter.endDate?.toISOString(),
        }
      : {
          [DATE_RANGE_START_QUERY_KEY]: undefined,
          [DATE_RANGE_END_QUERY_KEY]: undefined,
        }),
    [TIMESTAMP_QUERY_KEY]: dateFilter.timestamp,
  };
}
