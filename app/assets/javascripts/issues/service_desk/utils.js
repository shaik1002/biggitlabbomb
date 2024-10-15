import {
  OPERATOR_OR,
  TOKEN_TYPE_LABEL,
} from '~/vue_shared/components/filtered_search_bar/constants';
import { isSpecialFilter, isNotEmptySearchToken } from '~/issues/list/utils';
import {
  ALTERNATIVE_FILTER,
  NORMAL_FILTER,
  SPECIAL_FILTER,
  URL_PARAM,
} from '~/issues/list/constants';
import { filtersMap } from './constants';

const getFilterType = ({ type, value: { data, operator } }) => {
  const isUnionedLabel = type === TOKEN_TYPE_LABEL && operator === OPERATOR_OR;

  if (isUnionedLabel) {
    return ALTERNATIVE_FILTER;
  }
  if (isSpecialFilter(type, data)) {
    return SPECIAL_FILTER;
  }
  return NORMAL_FILTER;
};

export const convertToUrlParams = (filterTokens) => {
  const urlParamsMap = filterTokens.filter(isNotEmptySearchToken).reduce((acc, token) => {
    const filterType = getFilterType(token);
    const urlParam = filtersMap[token.type][URL_PARAM][token.value.operator]?.[filterType];
    return acc.set(
      urlParam,
      acc.has(urlParam) ? [acc.get(urlParam), token.value.data].flat() : token.value.data,
    );
  }, new Map());

  return Object.fromEntries(urlParamsMap);
};
