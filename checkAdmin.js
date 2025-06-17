const admin = require("firebase-admin");
admin.initializeApp({
  credential: admin.credential.cert(require("./serviceAccountKey.json")),
});

admin.auth().getUserByEmail("payard@gmail.com")
  .then(userRecord => {
    console.log(userRecord.customClaims); // Should show { admin: true }
  });