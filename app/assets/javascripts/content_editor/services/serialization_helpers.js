import { uniq, omit, isFunction } from 'lodash';
import { defaultMarkdownSerializer } from '~/lib/prosemirror_markdown_serializer';
import { removeLastSlashInUrlPath, removeUrlProtocol } from '../../lib/utils/url_utility';

const defaultAttrs = {
  td: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
  th: { colspan: 1, rowspan: 1, colwidth: null, align: 'left' },
};

const defaultIgnoreAttrs = ['sourceMarkdown', 'sourceMapKey'];

const ignoreAttrs = {
  dd: ['isTerm'],
  dt: ['isTerm'],
};

const tableMap = new WeakMap();

function containsOnlyText(node) {
  if (node.childCount === 1) {
    const child = node.child(0);
    return child.isText && child.marks.length === 0;
  }

  return false;
}

function containsParagraphWithOnlyText(cell) {
  if (cell.childCount === 1) {
    const child = cell.child(0);
    if (child.type.name === 'paragraph') {
      return containsOnlyText(child);
    }
  }

  return false;
}

function getRowsAndCells(table) {
  const cells = [];
  const rows = [];
  table.descendants((n) => {
    if (n.type.name === 'tableCell' || n.type.name === 'tableHeader') {
      cells.push(n);
      return false;
    }

    if (n.type.name === 'tableRow') {
      rows.push(n);
    }

    return true;
  });
  return { rows, cells };
}

// Buffers the output of the given action (fn) and returns the output that was written
// to the prosemirror-markdown serializer state output.
function buffer(state, action = () => {}) {
  const buf = state.out;
  action();
  const retval = state.out.substring(buf.length);
  state.out = buf;
  return retval;
}

function getChildren(node) {
  const children = [];
  for (let i = 0; i < node.childCount; i += 1) {
    children.push(node.child(i));
  }
  return children;
}

export function shouldRenderHTMLTable(table) {
  const { rows, cells } = getRowsAndCells(table);

  const cellChildCount = Math.max(...cells.map((cell) => cell.childCount));
  const maxColspan = Math.max(...cells.map((cell) => cell.attrs.colspan));
  const maxRowspan = Math.max(...cells.map((cell) => cell.attrs.rowspan));

  const rowChildren = rows.map((row) => uniq(getChildren(row).map((cell) => cell.type.name)));
  const cellTypeInFirstRow = rowChildren[0];
  const cellTypesInOtherRows = uniq(rowChildren.slice(1).map(([type]) => type));

  // if the first row has headers, and there are no headers anywhere else, render markdown table
  if (
    !(
      cellTypeInFirstRow.length === 1 &&
      cellTypeInFirstRow[0] === 'tableHeader' &&
      cellTypesInOtherRows.length === 1 &&
      cellTypesInOtherRows[0] === 'tableCell'
    )
  ) {
    return true;
  }

  if (cellChildCount === 1 && maxColspan === 1 && maxRowspan === 1) {
    // if all rows contain only one paragraph each and no rowspan/colspan, render markdown table
    const children = uniq(cells.map((cell) => cell.child(0).type.name));
    if (children.length === 1 && children[0] === 'paragraph') {
      return false;
    }
  }

  return true;
}

function htmlEncode(str = '') {
  return str
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/'/g, '&apos;')
    .replace(/"/g, '&quot;');
}

const shouldIgnoreAttr = (tagName, attrKey, attrValue) =>
  ignoreAttrs[tagName]?.includes(attrKey) ||
  defaultIgnoreAttrs.includes(attrKey) ||
  defaultAttrs[tagName]?.[attrKey] === attrValue;

export function openTag(tagName, attrs) {
  let str = `<${tagName}`;

  str += Object.entries(attrs || {})
    .map(([key, value]) => {
      if (shouldIgnoreAttr(tagName, key, value)) return '';

      return ` ${key}="${htmlEncode(value?.toString())}"`;
    })
    .join('');

  return `${str}>`;
}

export function closeTag(tagName) {
  return `</${tagName}>`;
}

function isInBlockTable(node) {
  return tableMap.get(node);
}

function isInTable(node) {
  return tableMap.has(node);
}

function setIsInBlockTable(table, value) {
  tableMap.set(table, value);

  const { rows, cells } = getRowsAndCells(table);
  rows.forEach((row) => tableMap.set(row, value));
  cells.forEach((cell) => {
    tableMap.set(cell, value);
    if (cell.childCount && cell.child(0).type.name === 'paragraph')
      tableMap.set(cell.child(0), value);
  });
}

function ensureSpace(state) {
  state.flushClose();
  if (!state.atBlank() && !state.out.endsWith(' ')) state.write(' ');
}

function unsetIsInBlockTable(table) {
  tableMap.delete(table);

  const { rows, cells } = getRowsAndCells(table);
  rows.forEach((row) => tableMap.delete(row));
  cells.forEach((cell) => {
    tableMap.delete(cell);
    if (cell.childCount) tableMap.delete(cell.child(0));
  });
}

function renderTagOpen(state, tagName, attrs) {
  state.ensureNewLine();
  state.write(openTag(tagName, attrs));
}

function renderTagClose(state, tagName, insertNewline = true) {
  state.write(closeTag(tagName));
  if (insertNewline) state.ensureNewLine();
}

function renderTableHeaderRowAsMarkdown(state, node, cellWidths) {
  state.flushClose(1);

  state.write('|');
  node.forEach((cell, _, i) => {
    if (i) state.write('|');

    state.write(cell.attrs.align === 'center' ? ':' : '-');
    state.write(state.repeat('-', cellWidths[i]));
    state.write(cell.attrs.align === 'center' || cell.attrs.align === 'right' ? ':' : '-');
  });
  state.write('|');

  state.closeBlock(node);
}

function renderTableRowAsMarkdown(state, node, isHeaderRow = false) {
  const cellWidths = [];

  state.flushClose(1);

  state.write('| ');
  node.forEach((cell, _, i) => {
    if (i) state.write(' | ');

    const { length } = state.out;
    const cellContent = buffer(state, () => state.render(cell, node, i));
    state.write(cellContent.replace(/\|/g, '\\|'));
    cellWidths.push(state.out.length - length);
  });
  state.write(' |');

  state.closeBlock(node);

  if (isHeaderRow) renderTableHeaderRowAsMarkdown(state, node, cellWidths);
}

function renderTableRowAsHTML(state, node) {
  renderTagOpen(state, 'tr');

  node.forEach((cell, _, i) => {
    const tag = cell.type.name === 'tableHeader' ? 'th' : 'td';

    renderTagOpen(state, tag, omit(cell.attrs, 'sourceMapKey', 'sourceMarkdown'));

    const buffered = buffer(state, () => {
      if (!containsParagraphWithOnlyText(cell)) {
        state.closeBlock(node);
        state.flushClose();
      }

      state.render(cell, node, i);
      state.flushClose(1);
    });
    if (buffered.includes('\\') && !buffered.includes('\n')) {
      state.out += `\n\n${buffered}\n`;
    } else {
      state.out += buffered;
    }

    renderTagClose(state, tag);
  });

  renderTagClose(state, 'tr');
}

export function renderContent(state, node, forceRenderInline) {
  if (node.type.inlineContent) {
    if (containsOnlyText(node)) {
      state.renderInline(node);
    } else {
      state.closeBlock(node);
      state.flushClose();
      state.renderInline(node);
      state.closeBlock(node);
      state.flushClose();
    }
  } else {
    const renderInline = forceRenderInline || containsParagraphWithOnlyText(node);
    if (!renderInline) {
      state.closeBlock(node);
      state.flushClose();
      state.renderContent(node);
      state.ensureNewLine();
    } else {
      state.renderInline(forceRenderInline ? node : node.child(0));
    }
  }
}

export function renderHTMLNode(tagName, forceRenderContentInline = false) {
  return (state, node) => {
    renderTagOpen(state, tagName, node.attrs);

    const buffered = buffer(state, () => renderContent(state, node, forceRenderContentInline));
    if (buffered.includes('\\') && !buffered.includes('\n')) {
      state.out += `\n\n${buffered}\n`;
    } else {
      state.out += buffered;
    }

    renderTagClose(state, tagName, false);

    if (forceRenderContentInline) {
      state.closeBlock(node);
      state.flushClose();
    }
  };
}

export function renderTableCell(state, node) {
  if (!isInBlockTable(node) || containsParagraphWithOnlyText(node)) {
    state.renderInline(node.child(0));
  } else {
    state.renderContent(node);
  }
}

export function renderTableRow(state, node) {
  if (isInBlockTable(node)) {
    renderTableRowAsHTML(state, node);
  } else {
    renderTableRowAsMarkdown(state, node, node.child(0).type.name === 'tableHeader');
  }
}

export function renderTable(state, node) {
  state.flushClose();
  setIsInBlockTable(node, shouldRenderHTMLTable(node));

  if (isInBlockTable(node)) renderTagOpen(state, 'table');

  state.renderContent(node);

  if (isInBlockTable(node)) renderTagClose(state, 'table');

  // ensure at least one blank line after any table
  state.closeBlock(node);
  state.flushClose();

  unsetIsInBlockTable(node);
}

export function renderHardBreak(state, node, parent, index) {
  const br = isInTable(parent) ? '<br>' : '\\\n';

  for (let i = index + 1; i < parent.childCount; i += 1) {
    if (parent.child(i).type !== node.type) {
      state.write(br);
      return;
    }
  }
}

function getMediaSrc(node, useCanonicalSrc = true) {
  const { canonicalSrc, src } = node.attrs;

  if (useCanonicalSrc) return canonicalSrc || src || '';
  return src || '';
}

export function renderImage(state, node) {
  const { alt, title, width, height, isReference } = node.attrs;
  const realSrc = getMediaSrc(node, state.options.useCanonicalSrc);
  // eslint-disable-next-line @gitlab/require-i18n-strings
  if (realSrc.startsWith('data:') || realSrc.startsWith('blob:')) return;

  if (realSrc) {
    const quotedTitle = title ? ` ${state.quote(title)}` : '';
    const sourceExpression = isReference ? `[${realSrc}]` : `(${realSrc}${quotedTitle})`;

    const sizeAttributes = [];
    if (width) {
      sizeAttributes.push(`width=${JSON.stringify(width)}`);
    }
    if (height) {
      sizeAttributes.push(`height=${JSON.stringify(height)}`);
    }

    const attributes = sizeAttributes.length ? `{${sizeAttributes.join(' ')}}` : '';

    state.write(`![${state.esc(alt || '')}]${sourceExpression}${attributes}`);
  }
}

export function renderPlayable(state, node) {
  renderImage(state, node);
}

export function renderHeading(state, node) {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  defaultMarkdownSerializer.nodes.heading(state, node);
}

export function renderBlockquote(state, node) {
  if (state.options.skipEmptyNodes) {
    if (!node.childCount) return;
    if (node.childCount === 1) {
      const child = node.child(0);
      if (child.type.name === 'paragraph' && !child.childCount) return;
    }
  }

  if (node.attrs.multiline) {
    state.write('>>>');
    state.ensureNewLine();
    state.renderContent(node);
    state.ensureNewLine();
    state.write('>>>');
    state.closeBlock(node);
  } else {
    state.wrapBlock('> ', null, node, () => state.renderContent(node));
  }
}

export function renderCodeBlock(state, node) {
  if (state.options.skipEmptyNodes && !node.childCount) return;

  let { language } = node.attrs;
  if (language === 'plaintext') language = '';

  const numBackticks = Math.max(2, node.textContent.match(/```+/g)?.[0]?.length || 0) + 1;
  const backticks = state.repeat('`', numBackticks);
  state.write(
    `${backticks}${
      (language || '') + (node.attrs.langParams ? `:${node.attrs.langParams}` : '')
    }\n`,
  );
  state.text(node.textContent, false);
  state.ensureNewLine();
  state.write(backticks);
  state.closeBlock(node);
}

const expandPreserveUnchangedConfig = (configOrRender) =>
  isFunction(configOrRender)
    ? { render: configOrRender, overwriteSourcePreservationStrategy: false, inline: false }
    : configOrRender;

export function preserveUnchanged(configOrRender) {
  return (state, node, parent, index) => {
    const { render, overwriteSourcePreservationStrategy, inline } = expandPreserveUnchangedConfig(
      configOrRender,
    );

    const { sourceMarkdown } = node.attrs;
    const same = state.options.changeTracker.get(node);

    if (same && !overwriteSourcePreservationStrategy) {
      state.write(sourceMarkdown);

      if (!inline) {
        state.closeBlock(node);
      }
    } else {
      render(state, node, parent, index, same, sourceMarkdown);
    }
  };
}

/**
 * We extracted this function from
 * https://github.com/ProseMirror/prosemirror-markdown/blob/master/src/to_markdown.ts#L350.
 *
 * We need to overwrite this function because we don’t want to wrap the list item nodes
 * with the bullet delimiter when the list item node hasn’t changed
 */
const renderList = (state, node, delim, firstDelim) => {
  if (state.closed && state.closed.type === node.type) state.flushClose(3);
  else if (state.inTightList) state.flushClose(1);

  const isTight =
    typeof node.attrs.tight !== 'undefined' ? node.attrs.tight : state.options.tightLists;
  const prevTight = state.inTightList;

  state.inTightList = isTight;

  node.forEach((child, _, i) => {
    const same = state.options.changeTracker.get(child);

    if (i && isTight) {
      state.flushClose(1);
    }

    if (same) {
      // Avoid wrapping list item when node hasn’t changed
      state.render(child, node, i);
    } else {
      state.wrapBlock(delim, firstDelim(i), node, () => state.render(child, node, i));
    }
  });

  state.inTightList = prevTight;
};

export const renderBulletList = (state, node) => {
  const { sourceMarkdown, bullet: bulletAttr } = node.attrs;
  const bullet = /^(\*|\+|-)\s/.exec(sourceMarkdown)?.[1] || bulletAttr || '*';

  renderList(state, node, '  ', () => `${bullet} `);
};

export function renderOrderedList(state, node) {
  const { sourceMarkdown } = node.attrs;
  let start;
  let delimiter;

  if (sourceMarkdown) {
    const match = /^(\d+)(\)|\.)/.exec(sourceMarkdown);
    start = parseInt(match[1], 10) || 1;
    [, , delimiter] = match;
  } else {
    start = node.attrs.start || 1;
    delimiter = node.attrs.parens ? ')' : '.';
  }

  const maxW = String(start + node.childCount - 1).length;
  const space = state.repeat(' ', maxW + 2);

  renderList(state, node, space, (i) => {
    const nStr = String(start + i);
    return `${state.repeat(' ', maxW - nStr.length) + nStr}${delimiter} `;
  });
}

export function renderReference(state, node) {
  ensureSpace(state);
  state.write(node.attrs.originalText || node.attrs.text);
}

export function renderReferenceLabel(state, node) {
  ensureSpace(state);
  state.write(node.attrs.originalText || `~${state.quote(node.attrs.text)}`);
}

const findChildWithMark = (mark, parent) => {
  let child;
  let offset;
  let index;

  parent.forEach((_child, _offset, _index) => {
    if (mark.isInSet(_child.marks)) {
      child = _child;
      offset = _offset;
      index = _index;
    }
  });

  return child ? { child, offset, index } : null;
};

const generateBoldTags = (wrapTagName = openTag) => {
  return (_, mark) => {
    const type = /^(\*\*|__|<strong|<b).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    switch (type) {
      case '**':
      case '__':
        return type;
      // eslint-disable-next-line @gitlab/require-i18n-strings
      case '<strong':
      case '<b':
        return wrapTagName(type.substring(1));
      default:
        return '**';
    }
  };
};

export const bold = {
  open: generateBoldTags(),
  close: generateBoldTags(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

const generateItalicTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    const type = /^(\*|_|<em|<i).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    switch (type) {
      case '*':
      case '_':
        return type;
      // eslint-disable-next-line @gitlab/require-i18n-strings
      case '<em':
      case '<i':
        return wrapTagName(type.substring(1));
      default:
        return '_';
    }
  };
};

export const italic = {
  open: generateItalicTag(),
  close: generateItalicTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};

function getMarkText(mark, parent) {
  return findChildWithMark(mark, parent).child?.text || '';
}

const generateCodeTag = (wrapTagName = openTag) => {
  const isOpen = wrapTagName === openTag;

  return (_, mark, parent) => {
    const type = /^(`|<code).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    if (type === '<code') {
      return wrapTagName(type.substring(1));
    }

    const childText = getMarkText(mark, parent);
    if (childText.includes('`')) {
      let tag = '``';
      if (childText.startsWith('`') || childText.endsWith('`'))
        tag = isOpen ? `${tag} ` : ` ${tag}`;
      return tag;
    }

    return '`';
  };
};

export const code = {
  open: generateCodeTag(),
  close: generateCodeTag(closeTag),
  mixable: true,
  escape: false,
  expelEnclosingWhitespace: true,
};

const LINK_HTML = 'linkHtml';
const LINK_MARKDOWN = 'linkMarkdown';

const linkType = (sourceMarkdown) => {
  const expression = /^(\[|<a).*/.exec(sourceMarkdown)?.[1];

  if (!expression || expression === '[') {
    return LINK_MARKDOWN;
  }

  return LINK_HTML;
};

const normalizeUrl = (url) => {
  const processedUrl = removeLastSlashInUrlPath(removeUrlProtocol(url));
  try {
    return decodeURIComponent(processedUrl);
  } catch {
    return processedUrl;
  }
};

/**
 * Validates that the provided URL is a valid GFM autolink
 *
 * @param {String} url
 * @returns Returns true when the URL is a valid GFM autolink
 */
const isValidAutolinkURL = (url) =>
  /(https?:\/\/)?([\w-])+\.{1}([a-zA-Z]{2,63})([/\w-]*)*\/?\??([^#\n\r]*)?#?([^\n\r]*)/.test(url);

/**
 * This function detects whether a link should be serialized
 * as an autolink.
 *
 * See https://github.github.com/gfm/#autolinks-extension-
 * to understand the parsing rules of autolinks.
 * */
const isAutoLink = (linkMark, parent) => {
  const { title, href } = linkMark.attrs;

  if (title || !/^\w+:/.test(href)) {
    return false;
  }

  const { child } = findChildWithMark(linkMark, parent);

  if (
    !child ||
    !child.isText ||
    !isValidAutolinkURL(href) ||
    normalizeUrl(child.text) !== normalizeUrl(href)
  ) {
    return false;
  }

  return true;
};

/**
 * Returns true if the user used brackets to the define
 * the autolink in the original markdown source
 */
const isBracketAutoLink = (sourceMarkdown) => /^<.+?>$/.test(sourceMarkdown);

function getLinkHref(mark, useCanonicalSrc = true) {
  const { canonicalSrc, href } = mark.attrs;

  if (useCanonicalSrc) return canonicalSrc || href || '';
  return href || '';
}

export const link = {
  open(state, mark, parent) {
    if (isAutoLink(mark, parent)) {
      return isBracketAutoLink(mark.attrs.sourceMarkdown) ? '<' : '';
    }

    const { href, title, sourceMarkdown, isGollumLink } = mark.attrs;

    // eslint-disable-next-line @gitlab/require-i18n-strings
    if (href.startsWith('data:') || href.startsWith('blob:')) return '';

    if (linkType(sourceMarkdown) === LINK_MARKDOWN) {
      if (isGollumLink) return '[[';
      return '[';
    }

    const attrs = {
      href: state.esc(getLinkHref(mark, state.options.useCanonicalSrc)),
    };

    if (title) {
      attrs.title = title;
    }

    return openTag('a', attrs);
  },
  close(state, mark, parent) {
    if (isAutoLink(mark, parent)) {
      return isBracketAutoLink(mark.attrs.sourceMarkdown) ? '>' : '';
    }

    const {
      href = '',
      title,
      sourceMarkdown,
      isReference,
      isGollumLink,
      canonicalSrc,
    } = mark.attrs;

    // eslint-disable-next-line @gitlab/require-i18n-strings
    if (href.startsWith('data:') || href.startsWith('blob:')) return '';

    if (isReference) {
      return `][${state.esc(getLinkHref(mark, state.options.useCanonicalSrc))}]`;
    }

    if (linkType(sourceMarkdown) === LINK_HTML) {
      return closeTag('a');
    }

    if (isGollumLink) {
      const text = getMarkText(mark, parent);
      const escapedCanonicalSrc = state.esc(canonicalSrc);

      if (text.toLowerCase() === escapedCanonicalSrc.toLowerCase()) {
        return ']]';
      }

      return `|${escapedCanonicalSrc}]]`;
    }

    return `](${state.esc(getLinkHref(mark, state.options.useCanonicalSrc))}${
      title ? ` ${state.quote(title)}` : ''
    })`;
  },
};

const generateStrikeTag = (wrapTagName = openTag) => {
  return (_, mark) => {
    if (mark.attrs.htmlTag) return wrapTagName(mark.attrs.htmlTag);

    const type = /^(~~|<del|<strike|<s).*/.exec(mark.attrs.sourceMarkdown)?.[1];

    switch (type) {
      case '~~':
        return type;
      case '<del': // eslint-disable-line @gitlab/require-i18n-strings
      case '<strike': // eslint-disable-line @gitlab/require-i18n-strings
      case '<s':
        return wrapTagName(type.substring(1));
      default:
        return '~~';
    }
  };
};

export const strike = {
  open: generateStrikeTag(),
  close: generateStrikeTag(closeTag),
  mixable: true,
  expelEnclosingWhitespace: true,
};
