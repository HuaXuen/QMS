import admin from "firebase-admin";
import * as functions from "firebase-functions";

function getDatabase() {
  if (!admin.apps.length) {
    throw new Error(
      "Firebase Admin is not initialized. Ensure index.js initializes it first."
    );
  }
  return admin.database();
}

export async function addRideAndBatches(data) {
  try {
    // Unwrap 'data' directly from the payload
    const {
      name,
      category,
      status,
      heightRequirement,
      queueTime,
      numOfRidersAllowed,
      createdAt,
    } = data.data; // Access the fields from the `data` object

    // Validate required fields
    const requiredFields = [
      "name",
      "category",
      "status",
      "heightRequirement",
      "queueTime",
      "numOfRidersAllowed",
      "createdAt",
    ];
    for (const field of requiredFields) {
      if (!data.data[field]) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          `Missing required field: ${field}`
        );
      }
    }

    const db = getDatabase();

    // Step 1: Add Ride
    const rideRef = db.ref("rides").push();
    const rideId = rideRef.key;
    await rideRef.set({
      name,
      category,
      status,
      heightRequirement,
      queueTime,
      numOfRidersAllowed,
      currentBatchId: "",
      createdAt,
    });

    // Step 2: Generate All Batches for Operating Hours
    const duration =
      numOfRidersAllowed <= 5 ? 5 : numOfRidersAllowed <= 10 ? 10 : 10;

    const startHour = 10; // Park opens at 10 AM
    const endHour = 18; // Park closes at 6 PM
    const now = new Date();
    let targetDate = new Date(now.getFullYear(), now.getMonth(), now.getDate());

    // Adjust target date based on time conditions
    if (
      now.getHours() >= 18 ||
      (now.getHours() < 10 && now.getMinutes() < 59)
    ) {
      if (now.getHours() >= 18) {
        console.log(
          "Current time is after 6:01 PM. Adjusting target date to next day."
        );
        targetDate.setDate(targetDate.getDate() + 1);
      }
    }

    targetDate.setHours(startHour, 0, 0, 0); // Set to start time: 10:00 AM

    const batches = {};
    for (let hour = startHour; hour < endHour; hour++) {
      for (let minute = 0; minute < 60; minute += duration) {
        const startAt = new Date(
          targetDate.getTime() + (hour - startHour) * 3600000 + minute * 60000
        );
        if (startAt.getTime() <= now.getTime()) {
          // Skip batches that have already passed
          continue;
        }
        const endAt = new Date(startAt.getTime() + duration * 60000);
        const batchKey = startAt.toISOString().replace(/[:.]/g, "-");
        batches[batchKey] = {
          startAt: startAt.getTime(),
          endAt: endAt.getTime(),
          queueIds: ["empty"],
          batchStatus: "pending",
          completedAt: 0, // Placeholder
          queueFilledAt: "Not Filled Up", // String for flexibility
        };
      }
    }

    // Step 3: Save All Batches to Database
    const batchPath = `rides/${rideId}/batches`;
    await db.ref(batchPath).update(batches);

    // Step 4: Update Current Batch ID
    const firstBatchId = Object.keys(batches)[0];
    if (firstBatchId) {
      await db.ref(`rides/${rideId}`).update({ currentBatchId: firstBatchId });
    }

    return { rideId };
  } catch (error) {
    console.error("Error in addRideAndBatches:", error.message);
    throw new functions.https.HttpsError("internal", error.message);
  }
}
