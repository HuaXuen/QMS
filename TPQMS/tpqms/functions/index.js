/* eslint-disable @typescript-eslint/no-unused-vars */
import admin from "firebase-admin";
import functionsV1 from "firebase-functions/v1"; // Use v1 for Pub/Sub scheduler
import functions from "firebase-functions/v2"; // Use v2 for modern features
import serviceAccount from "./keys/service-account.json" with { type: "json" };
import { setGlobalOptions } from "firebase-functions/v2";
setGlobalOptions({ region: "asia-southeast1" });


// Initialize Firebase Admin
admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
  databaseURL: "https://tpqms-fyp-default-rtdb.asia-southeast1.firebasedatabase.app/",
});

import { addRideAndBatches } from "./rides/addRide.js";
import { generateDailyBatches, cleanupAndArchiveBatches } from "./rides/automatedBatchFunction.js";

console.log("Initialized Firebase apps:", admin.apps); // Logs the list of initialized apps

// Callable Functions
export const addRideAndBatchesFunc = functions.https.onCall(addRideAndBatches);

export const generateDailyBatchesCallable = functions.https.onCall(async () => {
  try {
    console.log("Manually invoked batch generation...");
    await generateDailyBatches();
    return { message: "Daily batches generated successfully." };
  } catch (error) {
    console.error("Error generating daily batches:", error.message);
    throw new functions.https.HttpsError("internal", "Failed to generate daily batches.");
  }
});

export const cleanupAndArchiveBatchesCallable = functions.https.onCall(async (data, context) => {
  try {
    console.log("Manually invoked batch cleanup...");
    await cleanupAndArchiveBatches();
    return { message: "Batches archived and cleaned up successfully." };
  } catch (error) {
    console.error("Error cleaning up batches:", error.message);
    throw new functions.https.HttpsError("internal", "Failed to clean up batches.");
  }
});

// Scheduled Functions (using v1)
export const generateDailyBatchesScheduled = functionsV1.pubsub
  .schedule("every day 00:00")
  .timeZone("Asia/Kuala_Lumpur")
  .onRun(async () => {
    console.log("Running scheduled batch generation...");
    await generateDailyBatches();
  });

export const cleanupAndArchiveBatchesScheduled = functionsV1.pubsub
  .schedule("every day 22:00")
  .timeZone("Asia/Kuala_Lumpur")
  .onRun(async () => {
    console.log("Running scheduled batch cleanup...");
    await cleanupAndArchiveBatches();
  });
