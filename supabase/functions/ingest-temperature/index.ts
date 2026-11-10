import { createClient } from "npm:@supabase/supabase-js@2";

const jsonHeaders = {
  "Content-Type": "application/json",
};

function jsonResponse(body: Record<string, unknown>, status: number) {
  return new Response(JSON.stringify(body), {
    status,
    headers: jsonHeaders,
  });
}

function isValidTemperature(value: unknown): value is number {
  return (
    typeof value === "number" &&
    Number.isFinite(value) &&
    value >= -55 &&
    value <= 125
  );
}

function isValidOptionalTemperature(value: unknown): value is number | null {
  return value === null || isValidTemperature(value);
}

function isValidTimestamp(value: unknown): value is string {
  return typeof value === "string" && !Number.isNaN(Date.parse(value));
}

Deno.serve(async (request) => {
  if (request.method !== "POST") {
    return jsonResponse({ error: "Method not allowed" }, 405);
  }

  const expectedDeviceKey = Deno.env.get("DEVICE_API_KEY");
  const suppliedDeviceKey = request.headers.get("X-Device-Key");

  if (!expectedDeviceKey || suppliedDeviceKey !== expectedDeviceKey) {
    return jsonResponse({ error: "Unauthorized" }, 401);
  }

  let payload: Record<string, unknown>;

  try {
    payload = await request.json();
  } catch {
    return jsonResponse({ error: "Invalid JSON" }, 400);
  }

  const deviceId = payload.deviceId;
  const sessionId = payload.sessionId;
  const sampleIndex = payload.sampleIndex;
  const measuredAt = payload.measuredAt;
  const heaterRemovedAt = payload.heaterRemovedAt;
  const sensor1 = payload.sensor1;
  const sensor2 = payload.sensor2;

  if (
    typeof deviceId !== "string" ||
    !/^[a-zA-Z0-9_-]{1,64}$/.test(deviceId)
  ) {
    return jsonResponse({ error: "Invalid deviceId" }, 400);
  }

  if (
    typeof sessionId !== "string" ||
    !/^[0-9a-f]{8}-[0-9a-f]{4}-[1-5][0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i
      .test(
        sessionId,
      )
  ) {
    return jsonResponse({ error: "Invalid sessionId" }, 400);
  }

  if (
    typeof sampleIndex !== "number" ||
    !Number.isSafeInteger(sampleIndex) ||
    sampleIndex < 0
  ) {
    return jsonResponse({ error: "Invalid sampleIndex" }, 400);
  }

  if (measuredAt !== undefined && !isValidTimestamp(measuredAt)) {
    return jsonResponse({ error: "Invalid measuredAt" }, 400);
  }

  if (heaterRemovedAt !== undefined && !isValidTimestamp(heaterRemovedAt)) {
    return jsonResponse({ error: "Invalid heaterRemovedAt" }, 400);
  }

  if (
    !isValidOptionalTemperature(sensor1) ||
    !isValidOptionalTemperature(sensor2)
  ) {
    return jsonResponse({ error: "Invalid temperature" }, 400);
  }

  if (sensor1 === null && sensor2 === null) {
    return jsonResponse({ error: "At least one sensor must be present" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { data: session, error: sessionError } = await supabase
    .from("experiment_sessions")
    .select("id, device_id, ended_at")
    .eq("id", sessionId)
    .single();

  if (sessionError || !session || session.device_id !== deviceId) {
    return jsonResponse({ error: "Unknown session" }, 404);
  }

  if (session.ended_at !== null) {
    return jsonResponse({ error: "Session has ended" }, 409);
  }

  if (heaterRemovedAt !== undefined) {
    const { error: heaterUpdateError } = await supabase
      .from("experiment_sessions")
      .update({ heater_removed_at: heaterRemovedAt })
      .eq("id", sessionId)
      .is("heater_removed_at", null);

    if (heaterUpdateError) {
      console.error("Failed to record heater removal", heaterUpdateError);
      return jsonResponse({ error: "Failed to record heater removal" }, 500);
    }
  }

  const { error } = await supabase.from("temperature_readings").insert({
    device_id: deviceId,
    session_id: sessionId,
    sample_index: sampleIndex,
    sensor1,
    sensor2,
    ...(measuredAt === undefined ? {} : { measured_at: measuredAt }),
  });

  if (error) {
    console.error("Failed to store temperature reading", error);
    if (error.code === "23505") {
      return jsonResponse({ error: "Duplicate session sample" }, 409);
    }
    return jsonResponse({ error: "Failed to store reading" }, 500);
  }

  return jsonResponse({ ok: true, sessionId, sampleIndex }, 201);
});
