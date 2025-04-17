const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

exports.sendTestNotification = functions.firestore
    .document("tests/{testId}")

    .onCreate(async (snap, context) => {
      const testData = snap.data();
      const testId = context.params.testId;
      console.log("Created Test ID:", testId);

      console.log("New test created:", testData);

      const tokensSnapshot = await admin.firestore().collection("users").get();
      const tokens = tokensSnapshot.docs
          .map((doc) => doc.data().fcmToken)
          .filter((token) => token);

      console.log("Fetched tokens:", tokens);

      const message = {
        notification: {
          title: "A new test is available",
          body: testData.title || "A new test is available for you.",
        },
        tokens: tokens,
      };

      if (tokens.length === 0) {
        console.log("No tokens found. No notification sent.");
        return null;
      }

      return admin.messaging().sendMulticast(message)
          .then((response) => {
            console.log(
                response.successCount + " messages were sent successfully",
            );
            return null;
          }).catch((error) => {
            console.error("Error sending message:", error);
          });
    });

