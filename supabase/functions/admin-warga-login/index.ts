import { createClient } from "https://esm.sh/@supabase/supabase-js@2.45.4";

type RequestBody = {
  action?: "get" | "upsert";
  warga_id?: string;
  login?: string;
  kode_akses?: string;
};

const corsHeaders = {
  "Access-Control-Allow-Origin": "*",
  "Access-Control-Allow-Headers":
    "authorization, x-client-info, apikey, content-type",
};

Deno.serve(async (req) => {
  if (req.method === "OPTIONS") {
    return new Response("ok", { headers: corsHeaders });
  }

  try {
    const supabaseUrl = requiredEnv("SUPABASE_URL");
    const anonKey = requiredEnv("SUPABASE_ANON_KEY");
    const serviceRoleKey = requiredEnv("SUPABASE_SERVICE_ROLE_KEY");
    const pseudoEmailDomain =
      Deno.env.get("AUTH_PSEUDO_EMAIL_DOMAIN") ?? "rukunkita.internal";

    const authHeader = req.headers.get("Authorization") ?? "";
    const userClient = createClient(supabaseUrl, anonKey, {
      global: { headers: { Authorization: authHeader } },
    });
    const adminClient = createClient(supabaseUrl, serviceRoleKey);

    const {
      data: { user },
      error: userError,
    } = await userClient.auth.getUser();
    if (userError || !user) {
      return json({ error: "Unauthorized" }, 401);
    }

    const { data: actorProfile, error: actorError } = await adminClient
      .from("profiles")
      .select("role")
      .eq("id", user.id)
      .single();
    if (actorError) throw actorError;
    if (!["ADMIN", "SUPER_ADMIN"].includes(actorProfile.role)) {
      return json({ error: "Hanya ADMIN/SUPER_ADMIN yang boleh mengelola akun warga." }, 403);
    }

    const body = (await req.json()) as RequestBody;
    const wargaId = body.warga_id?.trim();
    if (!wargaId) return json({ error: "warga_id wajib diisi." }, 400);

    const { data: warga, error: wargaError } = await adminClient
      .from("warga_induk")
      .select("id, profile_id, nama_lengkap")
      .eq("id", wargaId)
      .single();
    if (wargaError) throw wargaError;

    if (body.action === "get") {
      return json(await accountPayload(adminClient, warga));
    }

    if (body.action !== "upsert") {
      return json({ error: "action tidak dikenal." }, 400);
    }

    const login = body.login?.trim().toLowerCase();
    if (!login) return json({ error: "Login username/email wajib diisi." }, 400);

    const email = login.includes("@") ? login : `${login}@${pseudoEmailDomain}`;
    const username = login.includes("@") ? login.split("@")[0] : login;
    const password = body.kode_akses?.trim();

    let profileId = warga.profile_id as string | null;
    let createdAuthUser = false;

    if (profileId) {
      const attributes: Record<string, unknown> = {
        email,
        user_metadata: { username },
      };
      if (password) attributes.password = password;

      const { error } = await adminClient.auth.admin.updateUserById(
        profileId,
        attributes,
      );
      if (error) throw error;
    } else {
      const existing = await findUserByEmail(adminClient, email);
      if (existing) {
        profileId = existing.id;
        await assertProfileCanBecomeWarga(adminClient, profileId);
        if (password) {
          const { error } = await adminClient.auth.admin.updateUserById(
            profileId,
            { password, user_metadata: { username } },
          );
          if (error) throw error;
        }
      } else {
        if (!password) {
          return json(
            {
              error:
                "Kode akses awal wajib diisi karena akun login belum ada.",
            },
            400,
          );
        }

        const { data, error } = await adminClient.auth.admin.createUser({
          email,
          password,
          email_confirm: true,
          user_metadata: { username },
        });
        if (error) throw error;
        profileId = data.user.id;
        createdAuthUser = true;
      }
    }

    await assertProfileNotLinkedElsewhere(adminClient, profileId, wargaId);

    const { error: profileError } = await adminClient.from("profiles").upsert({
      id: profileId,
      username,
      role: "WARGA",
    });
    if (profileError) throw profileError;

    const { error: linkError } = await adminClient
      .from("warga_induk")
      .update({ profile_id: profileId })
      .eq("id", wargaId);
    if (linkError) throw linkError;

    return json({
      warga_id: wargaId,
      profile_id: profileId,
      username,
      email,
      role: "WARGA",
      created_auth_user: createdAuthUser,
    });
  } catch (error) {
    return json({ error: errorMessage(error) }, 400);
  }
});

function requiredEnv(key: string): string {
  const value = Deno.env.get(key);
  if (!value) throw new Error(`Missing environment variable ${key}`);
  return value;
}

function json(payload: unknown, status = 200): Response {
  return new Response(JSON.stringify(payload), {
    status,
    headers: {
      ...corsHeaders,
      "Content-Type": "application/json",
    },
  });
}

function errorMessage(error: unknown): string {
  if (error instanceof Error) return error.message;
  return String(error);
}

async function accountPayload(
  adminClient: ReturnType<typeof createClient>,
  warga: { id: string; profile_id: string | null },
) {
  if (!warga.profile_id) {
    return {
      warga_id: warga.id,
      profile_id: null,
      username: null,
      email: null,
      role: null,
      created_auth_user: false,
    };
  }

  const { data: profile, error: profileError } = await adminClient
    .from("profiles")
    .select("username, role")
    .eq("id", warga.profile_id)
    .maybeSingle();
  if (profileError) throw profileError;

  const { data, error } = await adminClient.auth.admin.getUserById(
    warga.profile_id,
  );
  if (error) throw error;

  return {
    warga_id: warga.id,
    profile_id: warga.profile_id,
    username: profile?.username ?? null,
    email: data.user.email ?? null,
    role: profile?.role ?? null,
    created_auth_user: false,
  };
}

async function findUserByEmail(
  adminClient: ReturnType<typeof createClient>,
  email: string,
) {
  let page = 1;
  while (page <= 20) {
    const { data, error } = await adminClient.auth.admin.listUsers({
      page,
      perPage: 1000,
    });
    if (error) throw error;
    const found = data.users.find((user) => user.email?.toLowerCase() === email);
    if (found) return found;
    if (data.users.length < 1000) return null;
    page++;
  }
  return null;
}

async function assertProfileCanBecomeWarga(
  adminClient: ReturnType<typeof createClient>,
  profileId: string,
) {
  const { data, error } = await adminClient
    .from("profiles")
    .select("role")
    .eq("id", profileId)
    .maybeSingle();
  if (error) throw error;
  if (data?.role && data.role !== "WARGA") {
    throw new Error(
      "Akun login ini bukan role WARGA, jadi tidak bisa ditautkan ke data warga.",
    );
  }
}

async function assertProfileNotLinkedElsewhere(
  adminClient: ReturnType<typeof createClient>,
  profileId: string,
  wargaId: string,
) {
  const { data, error } = await adminClient
    .from("warga_induk")
    .select("id")
    .eq("profile_id", profileId)
    .neq("id", wargaId)
    .limit(1);
  if (error) throw error;
  if (data.length > 0) {
    throw new Error("Akun login ini sudah tertaut ke data warga lain.");
  }
}
