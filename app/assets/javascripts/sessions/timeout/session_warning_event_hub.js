import createEventHub from '~/helpers/event_hub_factory';
import { __ } from '~/locale';

export default createEventHub();

export const EVENT_OPEN_SESSION_WARNING_BANNER = Symbol(__('Open session expiration banner'));
export const EVENT_OPEN_SESSION_LOGOUT_MODAL = Symbol(__('Open session expiration modal'));
