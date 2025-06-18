const admin = require('firebase-admin');

// --- IMPORTANT ---
// 1. Place your service account key file in the same folder and name it 'serviceAccountKey.json'
// 2. Replace the values for uid and newPassword below

// --- CONFIGURATION ---
const serviceAccount = require('./serviceAccountKey.json');
const uid = 'bdemZ7whASfe66dHA7ShXrysvq93'; // The UID of the user you want to update
const newPassword = 'payardgt'; // The new password for the user

// --- SCRIPT ---
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount)
});

if (!uid || uid === 'REPLACE_WITH_USER_UID' || !newPassword || newPassword === 'REPLACE_WITH_NEW_STRONG_PASSWORD') {
  console.error('Error: Please replace the placeholder values for uid and newPassword in the script.');
  process.exit(1);
}

admin.auth().updateUser(uid, {
  password: newPassword
})
.then((userRecord) => {
  console.log('Successfully updated user password for:', userRecord.toJSON().email);
  process.exit(0);
})
.catch((error) => {
  console.error('Error updating user password:', error);
  process.exit(1);
});