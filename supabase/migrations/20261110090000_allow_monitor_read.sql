-- The mobile monitor uses the publishable key without user accounts.
-- Measurements are append-only through the protected Edge Function; clients
-- only receive read access.
grant select on table public.temperature_readings to anon;

drop policy if exists "Public monitor can read temperatures"
  on public.temperature_readings;

create policy "Public monitor can read temperatures"
  on public.temperature_readings
  for select
  to anon
  using (true);
