import { uniqueId } from 'lodash';
import { builders } from 'prosemirror-test-builder';
import Sourcemap from '~/content_editor/extensions/sourcemap';
import MarkdownSerializer from '~/content_editor/services/markdown_serializer';
import { createTiptapEditor } from './test_utils';

jest.mock('~/emoji');

export const tiptapEditor = createTiptapEditor([Sourcemap]);
const b = builders(tiptapEditor.schema);

export { b as builders };

export const serializeWithOptions = (options, ...content) =>
  new MarkdownSerializer().serialize(
    { doc: b.doc(...content), pristineDoc: options.pristineDoc && b.doc(options.pristineDoc) },
    options,
  );

export const serialize = (...content) =>
  new MarkdownSerializer().serialize({ doc: b.doc(...content), pristineDoc: b.doc(...content) });

export const source = (sourceMarkdown, sourceTagName) => ({
  sourceMarkdown,
  sourceMapKey: uniqueId('key-'),
  sourceTagName,
});

export const sourceTag = (sourceTagName) => ({ sourceTagName });
