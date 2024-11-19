import fs from 'fs/promises';
import path from 'path';
import yaml from 'js-yaml';
import { InternalEvents } from '~/tracking';

export async function readEventDefinition(eventName) {
  const paths = [
    path.join('config', 'events', `${eventName}.yml`),
    path.join('ee', 'config', 'events', `${eventName}.yml`),
  ];

  try {
    const data = await Promise.any(
      paths.map(async (filePath) => {
        try {
          const fileData = await fs.readFile(filePath, 'utf8');
          return yaml.safeLoad(fileData);
        } catch (err) {
          if (err.code === 'ENOENT') {
            throw new Error(`File not found at ${filePath}`);
          }
          throw new Error(`Error reading file at ${filePath}: ${err.message}`);
        }
      }),
    );
    return data;
  } catch (err) {
    throw new Error(
      `Event definition for ${eventName} not found in any path: ${err.errors.join(', ')}`,
    );
  }
}

export function useMockInternalEventsTracking() {
  let originalSnowplow;
  let trackEventSpy;
  let disposables = [];
  let eventDefinition;

  const validateEvent = async (eventName, properties) => {
    eventDefinition = await readEventDefinition(eventName);
    if (eventDefinition.action !== eventName) {
      throw new Error(`Event "${eventName}" is not defined in event definitions.`);
    }

    const definedProperties = eventDefinition.additional_properties || {};
    Object.keys(properties).forEach((prop) => {
      if (!definedProperties[prop]) {
        throw new Error(
          `Property "${prop}" is not defined for event "${eventName} in event definition file".`,
        );
      }
    });
  };

  const bindInternalEventDocument = (parent = document) => {
    const dispose = InternalEvents.bindInternalEventDocument(parent);
    disposables.push(dispose);

    const triggerEvent = (selectorOrEl, eventName = 'click') => {
      const event = new Event(eventName, { bubbles: true });
      const el =
        typeof selectorOrEl === 'string' ? parent.querySelector(selectorOrEl) : selectorOrEl;

      el.dispatchEvent(event);
    };

    return { triggerEvent, trackEventSpy };
  };

  beforeEach(() => {
    trackEventSpy = jest
      .spyOn(InternalEvents, 'trackEvent')
      .mockImplementation(async (eventName, properties = {}) => {
        await validateEvent(eventName, properties);
      });

    originalSnowplow = window.snowplow;
    window.snowplow = () => {};
  });

  afterEach(async () => {
    await Promise.all(disposables.map((dispose) => dispose && dispose()));
    disposables = [];
    window.snowplow = originalSnowplow;
  });

  return {
    bindInternalEventDocument,
  };
}
