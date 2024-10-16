import applyGitLabUIConfig from '@gitlab/ui/dist/config';
import { __, s__ } from '~/locale';
import { NEXT, PREV } from '~/vue_shared/components/pagination/constants';

applyGitLabUIConfig({
  translations: {
    'GlSearchBoxByType.input.placeholder': __('Search'),
    'GlSearchBoxByType.clearButtonTitle': __('Clear'),
    'GlSorting.sortAscending': __('Sort direction: Ascending'),
    'GlSorting.sortDescending': __('Sort direction: Descending'),
    'ClearIconButton.title': __('Clear'),
    'GlKeysetPagination.prevText': PREV,
    'GlKeysetPagination.navigationLabel': s__('Pagination|Pagination'),
    'GlKeysetPagination.nextText': NEXT,
  },
});
