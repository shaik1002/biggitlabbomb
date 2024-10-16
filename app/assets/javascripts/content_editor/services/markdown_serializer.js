import {
  MarkdownSerializer as ProseMirrorMarkdownSerializer,
  defaultMarkdownSerializer,
} from '~/lib/prosemirror_markdown_serializer';
import * as extensions from '../extensions';
import {
  renderCodeBlock,
  renderHardBreak,
  renderTable,
  renderTableCell,
  renderTableRow,
  openTag,
  closeTag,
  renderOrderedList,
  renderImage,
  renderHeading,
  renderBlockquote,
  renderPlayable,
  renderHTMLNode,
  renderContent,
  renderBulletList,
  renderReference,
  renderReferenceLabel,
  preserveUnchanged,
  bold,
  italic,
  link,
  code,
  strike,
} from './serialization_helpers';

const defaultSerializerConfig = {
  marks: {
    [extensions.Bold.name]: bold,
    [extensions.Italic.name]: italic,
    [extensions.Code.name]: code,
    [extensions.Subscript.name]: { open: '<sub>', close: '</sub>', mixable: true },
    [extensions.Superscript.name]: { open: '<sup>', close: '</sup>', mixable: true },
    [extensions.Highlight.name]: { open: '<mark>', close: '</mark>', mixable: true },
    [extensions.InlineDiff.name]: {
      mixable: true,
      open(_, mark) {
        return mark.attrs.type === 'addition' ? '{+' : '{-';
      },
      close(_, mark) {
        return mark.attrs.type === 'addition' ? '+}' : '-}';
      },
    },
    [extensions.Link.name]: link,
    [extensions.MathInline.name]: {
      open: (...args) => `$${defaultMarkdownSerializer.marks.code.open(...args)}`,
      close: (...args) => `${defaultMarkdownSerializer.marks.code.close(...args)}$`,
      escape: false,
    },
    [extensions.Strike.name]: strike,
    ...extensions.HTMLMarks.reduce(
      (acc, { name }) => ({
        ...acc,
        [name]: {
          mixable: true,
          open(state, node) {
            return openTag(name, node.attrs);
          },
          close: closeTag(name),
        },
      }),
      {},
    ),
  },

  nodes: {
    [extensions.Audio.name]: preserveUnchanged({
      render: renderPlayable,
      inline: true,
    }),
    [extensions.Blockquote.name]: preserveUnchanged(renderBlockquote),
    [extensions.BulletList.name]: preserveUnchanged(renderBulletList),
    [extensions.CodeBlockHighlight.name]: preserveUnchanged(renderCodeBlock),
    [extensions.Diagram.name]: preserveUnchanged(renderCodeBlock),
    [extensions.CodeSuggestion.name]: preserveUnchanged(renderCodeBlock),
    [extensions.DrawioDiagram.name]: preserveUnchanged({
      render: renderImage,
      inline: true,
    }),
    [extensions.DescriptionList.name]: renderHTMLNode('dl', true),
    [extensions.DescriptionItem.name]: (state, node, parent, index) => {
      if (index === 1) state.ensureNewLine();
      renderHTMLNode(node.attrs.isTerm ? 'dt' : 'dd')(state, node);
      if (index === parent.childCount - 1) state.ensureNewLine();
    },
    [extensions.Details.name]: renderHTMLNode('details', true),
    [extensions.DetailsContent.name]: (state, node, parent, index) => {
      if (!index) renderHTMLNode('summary')(state, node);
      else {
        if (index === 1) state.ensureNewLine();
        renderContent(state, node);
        if (index === parent.childCount - 1) state.ensureNewLine();
      }
    },
    [extensions.Emoji.name]: (state, node) => {
      const { name } = node.attrs;

      state.write(`:${name}:`);
    },
    [extensions.FootnoteDefinition.name]: preserveUnchanged((state, node) => {
      state.write(`[^${node.attrs.identifier}]: `);
      state.renderInline(node);
      state.ensureNewLine();
    }),
    [extensions.FootnoteReference.name]: preserveUnchanged({
      render: (state, node) => {
        state.write(`[^${node.attrs.identifier}]`);
      },
      inline: true,
    }),
    [extensions.Frontmatter.name]: preserveUnchanged((state, node) => {
      const { language } = node.attrs;
      const syntax = {
        toml: '+++',
        json: ';;;',
        yaml: '---',
      }[language];

      state.write(`${syntax}\n`);
      state.text(node.textContent, false);
      state.ensureNewLine();
      state.write(syntax);
      state.closeBlock(node);
    }),
    [extensions.Figure.name]: renderHTMLNode('figure'),
    [extensions.FigureCaption.name]: renderHTMLNode('figcaption'),
    [extensions.HardBreak.name]: preserveUnchanged(renderHardBreak),
    [extensions.Heading.name]: preserveUnchanged(renderHeading),
    [extensions.HorizontalRule.name]: preserveUnchanged(
      defaultMarkdownSerializer.nodes.horizontal_rule,
    ),
    [extensions.Image.name]: preserveUnchanged({
      render: renderImage,
      inline: true,
    }),
    [extensions.ListItem.name]: preserveUnchanged(defaultMarkdownSerializer.nodes.list_item),
    [extensions.Loading.name]: () => {},
    [extensions.OrderedList.name]: preserveUnchanged(renderOrderedList),
    [extensions.Paragraph.name]: preserveUnchanged(defaultMarkdownSerializer.nodes.paragraph),
    [extensions.Reference.name]: renderReference,
    [extensions.ReferenceLabel.name]: renderReferenceLabel,
    [extensions.ReferenceDefinition.name]: preserveUnchanged({
      render: (state, node, parent, index, same, sourceMarkdown) => {
        const nextSibling = parent.maybeChild(index + 1);

        state.text(same ? sourceMarkdown : node.textContent, false);

        /**
         * Do not insert a blank line between reference definitions
         * because it isn’t necessary and a more compact text format
         * is preferred.
         */
        if (!nextSibling || nextSibling.type.name !== extensions.ReferenceDefinition.name) {
          state.closeBlock(node);
        } else {
          state.ensureNewLine();
        }
      },
      overwriteSourcePreservationStrategy: true,
    }),
    [extensions.TableOfContents.name]: preserveUnchanged((state, node) => {
      state.write('[[_TOC_]]');
      state.closeBlock(node);
    }),
    [extensions.Table.name]: preserveUnchanged(renderTable),
    [extensions.TableCell.name]: renderTableCell,
    [extensions.TableHeader.name]: renderTableCell,
    [extensions.TableRow.name]: renderTableRow,
    [extensions.TaskItem.name]: preserveUnchanged((state, node) => {
      let symbol = ' ';
      if (node.attrs.inapplicable) symbol = '~';
      else if (node.attrs.checked) symbol = 'x';

      state.write(`[${symbol}] `);

      if (!node.textContent) state.write('&nbsp;');
      state.renderContent(node);
    }),
    [extensions.TaskList.name]: preserveUnchanged((state, node) => {
      if (node.attrs.numeric) renderOrderedList(state, node);
      else renderBulletList(state, node);
    }),
    [extensions.Text.name]: defaultMarkdownSerializer.nodes.text,
    [extensions.Video.name]: preserveUnchanged({
      render: renderPlayable,
      inline: true,
    }),
    [extensions.WordBreak.name]: (state) => state.write('<wbr>'),
    ...extensions.HTMLNodes.reduce((serializers, htmlNode) => {
      return {
        ...serializers,
        [htmlNode.name]: (state, node) => renderHTMLNode(htmlNode.options.tagName)(state, node),
      };
    }, {}),
  },
};

const createChangeTracker = (doc, pristineDoc) => {
  const changeTracker = new WeakMap();
  const pristineSourceMarkdownMap = new Map();

  if (doc && pristineDoc) {
    pristineDoc.descendants((node) => {
      if (node.attrs.sourceMapKey) {
        pristineSourceMarkdownMap.set(`${node.attrs.sourceMapKey}${node.type.name}`, node);
      }
    });
    doc.descendants((node) => {
      const pristineNode = pristineSourceMarkdownMap.get(
        `${node.attrs.sourceMapKey}${node.type.name}`,
      );

      if (pristineNode) {
        changeTracker.set(node, node.eq(pristineNode));
      }
    });
  }

  return changeTracker;
};

export default class MarkdownSerializer {
  /**
   * Converts a ProseMirror document to Markdown. See the
   * following documentation to learn how to implement
   * custom node and mark serializer functions.
   *
   * https://github.com/prosemirror/prosemirror-markdown
   *
   * @param {Object} params.nodes ProseMirror node serializer functions
   * @param {Object} params.marks ProseMirror marks serializer config
   *
   * @returns a markdown serializer
   */
  constructor({ serializerConfig = {} } = {}) {
    this.serializerConfig = serializerConfig;
  }
  /**
   * Serializes a ProseMirror document as Markdown. If a node contains
   * sourcemap metadata, the serializer is capable of restoring the
   * Markdown from which the node was generated using a Markdown
   * deserializer.
   *
   * See the Sourcemap metadata extension and the remark_markdown_deserializer
   * service for more information.
   *
   * @param {ProseMirror.Node} params.doc ProseMirror document to convert into Markdown
   * @param {ProseMirror.Node} params.pristineDoc Pristine version of the document that
   * should be converted into Markdown. This is used to detect which nodes in the document
   * changed.
   * @returns A String that represents the serialized document as Markdown
   */
  serialize({ doc, pristineDoc }, { useCanonicalSrc = true, skipEmptyNodes = false } = {}) {
    const changeTracker = createChangeTracker(doc, pristineDoc);
    const serializer = new ProseMirrorMarkdownSerializer(
      {
        ...defaultSerializerConfig.nodes,
        ...this.serializerConfig.nodes,
      },
      {
        ...defaultSerializerConfig.marks,
        ...this.serializerConfig.marks,
      },
    );

    return serializer.serialize(doc, {
      tightLists: true,
      useCanonicalSrc,
      skipEmptyNodes,
      changeTracker,
      escapeExtraCharacters: /<|>/g,
    });
  }
}
