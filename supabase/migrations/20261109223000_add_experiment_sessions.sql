create table if not exists public.experiment_sessions (
  id uuid primary key default gen_random_uuid(),
  device_id text not null default 'olaf-01',
  session_name text,
  started_at timestamptz not null default now(),
  heater_removed_at timestamptz,
  ended_at timestamptz,
  sample_interval_ms integer not null default 1000,
  created_at timestamptz not null default now(),
  constraint experiment_sessions_device_id_valid
    check (device_id ~ '^[a-zA-Z0-9_-]{1,64}$'),
  constraint experiment_sessions_sample_interval_one_second
    check (sample_interval_ms = 1000),
  constraint experiment_sessions_heater_removed_after_start
    check (heater_removed_at is null or heater_removed_at >= started_at),
  constraint experiment_sessions_ended_after_start
    check (ended_at is null or ended_at >= started_at)
);

create table if not exists public.experiment_session_sensors (
  id bigint generated always as identity primary key,
  session_id uuid not null
    references public.experiment_sessions (id) on delete cascade,
  sensor_slot text not null,
  sensor_name text not null,
  stage_number smallint not null,
  is_present boolean not null default true,
  created_at timestamptz not null default now(),
  constraint experiment_session_sensors_slot_valid
    check (sensor_slot ~ '^[a-zA-Z0-9_-]{1,32}$'),
  constraint experiment_session_sensors_name_not_blank
    check (length(btrim(sensor_name)) > 0),
  constraint experiment_session_sensors_stage_positive
    check (stage_number > 0),
  constraint experiment_session_sensors_session_slot_unique
    unique (session_id, sensor_slot),
  constraint experiment_session_sensors_session_stage_unique
    unique (session_id, stage_number)
);

alter table public.temperature_readings
  add column if not exists session_id uuid
    references public.experiment_sessions (id) on delete cascade,
  add column if not exists sample_index bigint;

-- Missing sensors use NULL temperatures. Sensor identity and per-stage
-- presence are stored once in experiment_session_sensors for the session.
alter table public.temperature_readings
  alter column sensor1 drop not null,
  alter column sensor2 drop not null;

alter table public.temperature_readings
  drop constraint if exists temperature_readings_sample_index_nonnegative;

alter table public.temperature_readings
  add constraint temperature_readings_sample_index_nonnegative
    check (sample_index is null or sample_index >= 0);

create unique index if not exists temperature_readings_session_sample_idx
  on public.temperature_readings (session_id, sample_index)
  where session_id is not null and sample_index is not null;

create index if not exists temperature_readings_session_time_idx
  on public.temperature_readings (session_id, measured_at desc)
  where session_id is not null;

alter table public.experiment_sessions enable row level security;
alter table public.experiment_session_sensors enable row level security;

revoke all on table public.experiment_sessions from anon, authenticated;
revoke all on table public.experiment_session_sensors from anon, authenticated;
grant select on table public.experiment_sessions to authenticated;
grant select on table public.experiment_session_sensors to authenticated;

create policy "Authenticated users can read experiment sessions"
  on public.experiment_sessions
  for select
  to authenticated
  using (true);

create policy "Authenticated users can read session sensors"
  on public.experiment_session_sensors
  for select
  to authenticated
  using (true);

comment on column public.experiment_sessions.heater_removed_at is
  'Timestamp when the heating element was removed during the experiment.';
comment on column public.experiment_sessions.sample_interval_ms is
  'Required temperature sampling interval. Fixed at 1000 ms.';
comment on column public.experiment_session_sensors.stage_number is
  'Physical experiment stage/tier where the sensor belongs.';
comment on column public.experiment_session_sensors.is_present is
  'Whether a sensor is installed at this stage for the session.';
comment on column public.temperature_readings.measured_at is
  'Actual timestamp at which the temperature sample was measured.';
comment on column public.temperature_readings.sample_index is
  'Zero-based sequence number. Increment once per 1000 ms session interval.';
