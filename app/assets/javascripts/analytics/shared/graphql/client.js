import createDefaultClient from '~/lib/graphql';
import { resolvers } from './resolvers';
import typeDefs from './typedefs.graphql';

// TODO: do we need typedefs?
export const defaultClient = createDefaultClient(resolvers, { typeDefs });
