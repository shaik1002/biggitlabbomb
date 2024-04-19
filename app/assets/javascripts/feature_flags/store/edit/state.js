export default ({ path, endpoint }) => ({
  endpoint,
  path,
  isSendingRequest: false,
  error: [],

  name: null,
  description: null,
  scopes: [],
  isLoading: false,
  hasError: false,
  iid: null,
  active: true,
  strategies: [],
});
