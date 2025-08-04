import * as admin from 'firebase-admin';
import * as fs from 'fs';


/**
 * Initializes Firebase Admin SDK with explicit credentials.
 * @param {string} serviceAccountPath - The file path to the service account JSON.
 */
const initializeFirebase = (serviceAccountPath: string) => {
  try {
    const serviceAccount = JSON.parse(fs.readFileSync(serviceAccountPath, 'utf8'));
    admin.initializeApp({
      credential: admin.credential.cert(serviceAccount)
    });
    console.log('✅ Firebase Admin SDK initialized successfully.');
  } catch (error) {
    console.error('❌ Failed to initialize Firebase Admin SDK. Please check your file path and the contents of the service account JSON file.');
    console.error(error);
    process.exit(1);
  }
};

/**
 * Fetches a user by their email address from Firebase Authentication
 * and prints their custom claims to the console.
 * @param {string} email The email address of the user to look up.
 */
const checkUserClaims = async (email: string) => {
  try {
    console.log(`Fetching user with email: ${email}...`);
    const userRecord = await admin.auth().getUserByEmail(email);
    const customClaims = userRecord.customClaims || {};

    console.log('----------------------------------------');
    console.log(`User UID: ${userRecord.uid}`);
    console.log(`Display Name: ${userRecord.displayName}`);
    console.log('----------------------------------------');

    if (Object.keys(customClaims).length === 0) {
      console.log('✅ This user has no custom claims set.');
    } else {
      console.log('✅ Custom Claims Found:');
      console.log(JSON.stringify(customClaims, null, 2));
    }
    console.log('----------------------------------------');
  } catch (error: any) {
    if (error.code === 'auth/user-not-found') {
      console.error(`❌ Error: No user found for email "${email}".`);
    } else {
      console.error('❌ An unexpected error occurred:');
      console.error(error);
    }
    process.exit(1);
  }
};

// --- Script Execution ---
const emailArg = process.argv[2];
const filePathArg = process.argv[3];

if (!emailArg || !filePathArg) {
  console.error('Usage: npx ts-node functions/scripts/check-claims.ts <user-email> "<path-to-service-account.json>"');
  process.exit(1);
}

// Initialize first, then run the check
initializeFirebase(filePathArg);

(async () => {
  await checkUserClaims(emailArg);
  process.exit(0);
})();