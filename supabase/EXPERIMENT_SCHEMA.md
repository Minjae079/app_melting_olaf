# Experiment data model

Each experiment is represented by one row in `experiment_sessions`. Temperature
samples reference that session and use a zero-based `sample_index` that advances
once every second.

## Start a session

```sql
insert into public.experiment_sessions (device_id, session_name)
values ('olaf-01', 'Ice test 001')
returning id;
```

Register every physical stage, including stages where a sensor is intentionally
absent:

```sql
insert into public.experiment_session_sensors
  (session_id, sensor_slot, sensor_name, stage_number, is_present)
values
  ('<session-id>', 'sensor1', 'Upper sensor', 1, true),
  ('<session-id>', 'sensor2', 'Lower sensor', 2, false);
```

## Record one-second samples

Call `ingest-temperature` once per second. `sampleIndex` starts at zero and must
increase by one for each call. `measuredAt` is the actual measurement timestamp;
if omitted, the database insertion time is used.

```json
{
  "deviceId": "olaf-01",
  "sessionId": "<session-id>",
  "sampleIndex": 0,
  "measuredAt": "2026-11-09T22:15:00.000Z",
  "sensor1": 21.4,
  "sensor2": null
}
```

The `(session_id, sample_index)` unique index rejects duplicate samples. A null
temperature represents a sensor that is not present or did not produce a value.

## Record heater removal

Send `heaterRemovedAt` with the first sample collected after removal. The ingest
function records only the first heater-removal timestamp for the session.

```json
{
  "deviceId": "olaf-01",
  "sessionId": "<session-id>",
  "sampleIndex": 42,
  "measuredAt": "2026-11-09T22:15:42.000Z",
  "heaterRemovedAt": "2026-11-09T22:15:41.620Z",
  "sensor1": 18.7,
  "sensor2": null
}
```

Close the session after the experiment:

```sql
update public.experiment_sessions
set ended_at = now()
where id = '<session-id>';
```
