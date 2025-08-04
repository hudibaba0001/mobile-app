import * as admin from 'firebase-admin';
import * as fs from 'fs';

/**
 * Sets a custom claim { admin: true } for a user identified by their email.
 * @param {string} email The email address of the user to grant admin privileges.
 */
const setAdminClaim = async (email: string) => {
  try {
    console.log(`Looking up user by email: ${email}...`);
    const user = await admin.auth().getUserByEmail(email);

    console.log(`Setting custom claim { admin: true } for UID: ${user.uid}...`);
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });

    console.log('----------------------------------------');
    console.log(`✅ Success! Custom claim { admin: true } has been set for ${email}.`);
    console.log('The user must sign out and sign back in for the changes to take effect.');
    console.log('----------------------------------------');

  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      console.error(`❌ Error: No user found for email "${email}".`);
    } else {
      console.error('❌ An unexpected error occurred while setting the admin claim:');
      console.error(error);
    }
    process.exit(1);
  }
};

// --- Script Execution ---
const emailArg = process.argv[2];
const filePathArg = process.argv[3];

if (!emailArg || !filePathArg) {
  console.error('Usage: npx ts-node functions/scripts/set-admin.ts <user-email> "<path-to-service-account.json>"');
  process.exit(1);
}

try {
  // Initialize Firebase Admin SDK with credentials from a file path
  const serviceAccount = JSON.parse(fs.readFileSync(filePathArg, 'utf8'));
  admin.initializeApp({
    credential: admin.credential.cert(serviceAccount)
  });

  // Run the main function
  setAdminClaim(emailArg);

} catch (error) {
  console.error('❌ Failed to initialize Firebase Admin SDK. Please check your file path and the contents of the service account JSON file.');
  console.error(error);
  process.exit(1);
}