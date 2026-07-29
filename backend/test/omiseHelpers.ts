import { env } from "../src/config/env";

/// Tokenizes a real card against Omise's sandbox Vault API directly over
/// HTTP — the same one-time-use token flow the mobile app's card form uses,
/// reproduced here so payment tests exercise a real charge end-to-end
/// rather than mocking Omise (matching how this integration was originally
/// verified by hand against the sandbox).
export async function createTestCardToken(cardNumber = "4242424242424242"): Promise<string> {
  const params = new URLSearchParams({
    "card[name]": "Test User",
    "card[number]": cardNumber,
    "card[expiration_month]": "12",
    "card[expiration_year]": "2030",
    "card[security_code]": "123",
  });

  const auth = Buffer.from(`${env.omisePublicKey}:`).toString("base64");
  const res = await fetch("https://vault.omise.co/tokens", {
    method: "POST",
    headers: {
      Authorization: `Basic ${auth}`,
      "Content-Type": "application/x-www-form-urlencoded",
    },
    body: params,
  });
  const data = (await res.json()) as { id?: string; message?: string };
  if (!data.id) throw new Error(`Failed to create test card token: ${data.message}`);
  return data.id;
}
