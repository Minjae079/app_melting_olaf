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
  const sensor1 = payload.sensor1;
  const sensor2 = payload.sensor2;

  if (
    typeof deviceId !== "string" ||
    !/^[a-zA-Z0-9_-]{1,64}$/.test(deviceId)
  ) {
    return jsonResponse({ error: "Invalid deviceId" }, 400);
  }

  if (!isValidTemperature(sensor1) || !isValidTemperature(sensor2)) {
    return jsonResponse({ error: "Invalid temperature" }, 400);
  }

  const supabaseUrl = Deno.env.get("SUPABASE_URL");
  const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");

  if (!supabaseUrl || !serviceRoleKey) {
    return jsonResponse({ error: "Server configuration error" }, 500);
  }

  const supabase = createClient(supabaseUrl, serviceRoleKey, {
    auth: { persistSession: false },
  });

  const { error } = await supabase.from("temperature_readings").insert({
    device_id: deviceId,
    sensor1,
    sensor2,
  });

  if (error) {
    console.error("Failed to store temperature reading", error);
    return jsonResponse({ error: "Failed to store reading" }, 500);
  }

  return jsonResponse({ ok: true }, 201);
});
