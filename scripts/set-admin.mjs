// يمنح (أو يسحب) صلاحية الإدارة لحساب بريد إلكتروني عبر Custom Claim  { admin: true }.
//
// الاستخدام:
//   cd scripts && npm install
//   export GOOGLE_APPLICATION_CREDENTIALS=/path/to/service-account.json
//   node set-admin.mjs admin@example.com          # منح
//   node set-admin.mjs admin@example.com --revoke # سحب
//
// ملف service-account.json من: Firebase Console ← Project settings ← Service accounts ← Generate new private key.
// لا ترفع هذا الملف إلى GitHub أبداً.

import { initializeApp, applicationDefault } from 'firebase-admin/app';
import { getAuth } from 'firebase-admin/auth';

const [email, flag] = process.argv.slice(2);
if (!email) {
  console.error('Usage: node set-admin.mjs <email> [--revoke]');
  process.exit(1);
}

initializeApp({ credential: applicationDefault() });
const auth = getAuth();

const user = await auth.getUserByEmail(email);
const revoke = flag === '--revoke';
const claims = { ...(user.customClaims ?? {}) };
if (revoke) delete claims.admin;
else claims.admin = true;

await auth.setCustomUserClaims(user.uid, claims);
console.log(`${revoke ? 'Revoked' : 'Granted'} admin for ${email} (uid: ${user.uid}).`);
console.log('The user must sign out and back in for the change to take effect.');
