import { GlDaterangePicker } from '@gitlab/ui';
import { shallowMountExtended } from 'helpers/vue_test_utils_helper';
import DateRangesDropdown from '~/analytics/shared/components/date_ranges_dropdown.vue';
import DateRangeFilter from '~/observability/components/date_range_filter.vue';
import { useFakeDate } from 'helpers/fake_date';

describe('DateRangeFilter', () => {
  // Apr 23th, 2024 4:00 (3 = April)
  useFakeDate(2024, 3, 23, 4);

  let wrapper;

  const defaultProps = {
    selected: {
      value: '1h',
      startDate: new Date(),
      endDate: new Date(),
    },
  };

  const mount = (props = defaultProps) => {
    wrapper = shallowMountExtended(DateRangeFilter, {
      propsData: props,
    });
  };

  beforeEach(() => {
    mount();
  });

  const findDateRangesDropdown = () => wrapper.findComponent(DateRangesDropdown);
  const findDateRangesPicker = () => wrapper.findComponent(GlDaterangePicker);

  it('renders the date ranges dropdown with the default selected value and options', () => {
    const dateRangesDropdown = findDateRangesDropdown();
    expect(dateRangesDropdown.exists()).toBe(true);
    expect(dateRangesDropdown.props('selected')).toBe(defaultProps.selected.value);
    expect(dateRangesDropdown.props('dateRangeOptions')).toMatchInlineSnapshot(`
      Array [
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-23T03:55:00.000Z,
          "text": "Last 5 minutes",
          "value": "5m",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-23T03:45:00.000Z,
          "text": "Last 15 minutes",
          "value": "15m",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-23T03:30:00.000Z,
          "text": "Last 30 minutes",
          "value": "30m",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-23T03:00:00.000Z,
          "text": "Last 1 hour",
          "value": "1h",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-23T00:00:00.000Z,
          "text": "Last 4 hours",
          "value": "4h",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-22T16:00:00.000Z,
          "text": "Last 12 hours",
          "value": "12h",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-22T04:00:00.000Z,
          "text": "Last 24 hours",
          "value": "24h",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-16T04:00:00.000Z,
          "text": "Last 7 days",
          "value": "7d",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-09T04:00:00.000Z,
          "text": "Last 14 days",
          "value": "14d",
        },
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-03-24T04:00:00.000Z,
          "text": "Last 30 days",
          "value": "30d",
        },
      ]
    `);
  });

  it('renders dateRangeOptions based on dateOptions if specified', () => {
    mount({ ...defaultProps, dateOptions: [{ value: '7m', title: 'Last 7 minutes' }] });

    expect(findDateRangesDropdown().props('dateRangeOptions')).toMatchInlineSnapshot(`
      Array [
        Object {
          "endDate": 2024-04-23T04:00:00.000Z,
          "startDate": 2024-04-23T03:53:00.000Z,
          "text": "Last 7 minutes",
          "value": "7m",
        },
      ]
    `);
  });

  it('does not set the selected value if not specified', () => {
    mount({ selected: undefined });

    expect(findDateRangesDropdown().props('selected')).toBe('');
  });

  it('renders the daterange-picker if custom option is selected', () => {
    const timeRange = {
      startDate: new Date('2022-01-01'),
      endDate: new Date('2022-01-02'),
    };
    mount({
      selected: { value: 'custom', startDate: timeRange.startDate, endDate: timeRange.endDate },
    });

    expect(findDateRangesPicker().exists()).toBe(true);
    expect(findDateRangesPicker().props('defaultStartDate')).toBe(timeRange.startDate);
    expect(findDateRangesPicker().props('defaultEndDate')).toBe(timeRange.endDate);
  });

  it('emits the onDateRangeSelected event when the time range is selected', async () => {
    const timeRange = {
      value: '24h',
      startDate: new Date('2022-01-01'),
      endDate: new Date('2022-01-02'),
    };
    await findDateRangesDropdown().vm.$emit('selected', timeRange);

    expect(wrapper.emitted('onDateRangeSelected')).toEqual([[{ ...timeRange }]]);
  });

  it('emits the onDateRangeSelected event when a custom time range is selected', async () => {
    const timeRange = {
      startDate: new Date('2021-01-01'),
      endDate: new Date('2021-01-02'),
    };
    await findDateRangesDropdown().vm.$emit('customDateRangeSelected');

    expect(findDateRangesPicker().props('startOpened')).toBe(true);
    expect(wrapper.emitted('onDateRangeSelected')).toBeUndefined();

    await findDateRangesPicker().vm.$emit('input', timeRange);

    expect(wrapper.emitted('onDateRangeSelected')).toEqual([
      [
        {
          ...timeRange,
          value: 'custom',
        },
      ],
    ]);
  });

  describe('start opened', () => {
    it('sets startOpened to true if custom date is selected without start and end date', () => {
      mount({ selected: { value: 'custom' } });

      expect(findDateRangesPicker().props('startOpened')).toBe(true);
    });

    it('sets startOpened to false if custom date is selected with start and end date', () => {
      mount({
        selected: {
          value: 'custom',
          startDate: new Date('2022-01-01'),
          endDate: new Date('2022-01-02'),
        },
      });

      expect(findDateRangesPicker().props('startOpened')).toBe(false);
    });

    it('sets startOpend to true if customDateRangeSelected is emitted', async () => {
      await findDateRangesDropdown().vm.$emit('customDateRangeSelected');

      expect(findDateRangesPicker().props('startOpened')).toBe(true);
    });
  });

  it('sets the max-date to tomorrow', async () => {
    await findDateRangesDropdown().vm.$emit('customDateRangeSelected');

    expect(findDateRangesPicker().props('defaultMaxDate').toISOString()).toBe(
      '2024-04-24T00:00:00.000Z',
    );
  });
  it('sets max-date-range to maxDateRange', () => {
    mount({
      selected: {
        value: 'custom',
        startDate: new Date('2022-01-01'),
        endDate: new Date('2022-01-02'),
      },
      maxDateRange: 7,
    });

    expect(findDateRangesPicker().props('maxDateRange')).toBe(7);
  });
});
