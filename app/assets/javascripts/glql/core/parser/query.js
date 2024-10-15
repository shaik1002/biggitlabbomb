import { uniq, once } from 'lodash';
import { GitLabQueryLanguage as QueryParser } from '@gitlab/query-language';
import { extractGroupOrProject } from '../../utils/common';

const REQUIRED_QUERY_FIELDS = ['id', 'iid', 'title', 'webUrl', 'reference', 'state', 'type'];

const initParser = once(async () => {
  const parser = QueryParser();
  const { group, project } = extractGroupOrProject();

  parser.group = group;
  parser.project = project;
  parser.username = gon.current_username;
  await parser.initialize();

  return parser;
});

export const parseQuery = async (query, config) => {
  const parser = await initParser();
  parser.fields = uniq([...REQUIRED_QUERY_FIELDS, ...config.fields.map(({ name }) => name)]);

  const { output } = parser.compile(config.target || 'graphql', query, config.limit);

  if (output.toLowerCase().startsWith('error')) throw new Error(output.replace(/^error: /i, ''));

  return output;
};
