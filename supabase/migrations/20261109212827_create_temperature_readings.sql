create table if not exists public.temperature_readings (
  id bigint generated always as identity primary key,
  device_id text not null default 'olaf-01',
  sensor1 double precision not null,
  sensor2 double precision not null,
  measured_at timestamptz not null default now(),
  constraint sensor1_valid check (sensor1 between -55 and 125),
  constraint sensor2_valid check (sensor2 between -55 and 125)
);

create index if not exists temperature_readings_device_time_idx
  on public.temperature_readings (device_id, measured_at desc);

alter table public.temperature_readings enable row level security;

revoke all on table public.temperature_readings from anon, authenticated;
grant select on table public.temperature_readings to authenticated;

drop policy if exists "Authenticated users can read temperatures"
  on public.temperature_readings;

create policy "Authenticated users can read temperatures"
  on public.temperature_readings
  for select
  to authenticated
  using (true);

do $$
begin
  alter publication supabase_realtime
    add table public.temperature_readings;
exception
  when duplicate_object then null;
end $$;
