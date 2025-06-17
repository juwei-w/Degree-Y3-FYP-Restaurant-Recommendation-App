// setAdmin.js
const admin = require("firebase-admin");

// Download your service account key from Firebase Console > Project Settings > Service Accounts
const serviceAccount = require("./serviceAccountKey.json");

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const email = "payardmmu@gmail.com";

admin.auth().getUserByEmail(email)
  .then((user) => {
    return admin.auth().setCustomUserClaims(user.uid, { admin: true });
  })
  .then(() => {
    console.log(`Success! ${email} is now an admin.`);
    process.exit(0);
  })
  .catch((error) => {
    console.error("Error:", error);
    process.exit(1);
  });