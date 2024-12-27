// /* eslint-disable @typescript-eslint/no-unused-vars */
// import * as functions from "firebase-functions/v1";
// import { getDatabase } from "./utils/database.js";
// import admin from "firebase-admin";

// export const generateDailyBatches = functions.pubsub
//   .schedule("every day 00:00")
//   .timeZone("Asia/Kuala_Lumpur")
//   .onRun(async (context) => {
//     const db = getDatabase(); // Use the helper function here
//     const ridesRef = db.ref("rides");

//     const ridesSnapshot = await ridesRef.once("value");
//     const today = new Date();
//     today.setHours(10, 0, 0, 0); // Start time: 10:00 AM

//     const endHour = 18; // End time: 6 PM
//     const promises = [];
//     ridesSnapshot.forEach((rideSnapshot) => {
//       const ride = rideSnapshot.val();
//       const duration = ride.numOfRidersAllowed <= 5 ? 5 : 10; // Batch duration in minutes
//       const batches = {};

//       for (let hour = 10; hour < endHour; hour++) {
//         for (let minute = 0; minute < 60; minute += duration) {
//           const startAt = new Date(
//             today.getTime() + (hour - 10) * 3600000 + minute * 60000
//           );
//           const endAt = new Date(startAt.getTime() + duration * 60000);
//           const batchKey = startAt.toISOString().replace(/[:.]/g, "-");

//           batches[batchKey] = {
//             startAt: startAt.getTime(),
//             endAt: endAt.getTime(),
//             queueIds: ["empty"],
//             status: "pending",
//           };
//         }
//       }

//       const batchPath = `rides/${rideSnapshot.key}/batches`;
//       promises.push(
//         db
//           .ref(batchPath)
//           .set(batches)
//           .then(() => {
//             console.log(`Batches generated for ride ${rideSnapshot.key}`);
//           })
//       );
//     });

//     await Promise.all(promises);
//     console.log("Daily batch generation completed.");

//     console.log("Daily batch generation completed.");
//   });

// export const cleanupAndArchiveBatches = functions.pubsub
//   .schedule("every day 22:00")
//   .timeZone("Asia/Kuala_Lumpur")
//   .onRun(async (context) => {
//     const db = getDatabase();
//     const firestore = admin.firestore();
//     const ridesRef = db.ref("rides");

//     const now = new Date();
//     const todayKey = now.toISOString().split("T")[0]; // e.g., "2024-12-25"

//     const ridesSnapshot = await ridesRef.once("value");
//     const promises = [];

//     ridesSnapshot.forEach(async (rideSnapshot) => {
//       const rideId = rideSnapshot.key;
//       const rideData = rideSnapshot.val();

//       const batchesSnapshot = await db
//         .ref(`rides/${rideId}/batches`)
//         .once("value");
//       const batches = batchesSnapshot.val();

//       // Aggregate analytics
//       let totalVisitors = 0;
//       let totalQueueTime = 0;
//       let batchCount = 0;
//       let busiestBatchStartTime = null;
//       let maxVisitorsInBatch = 0;

//       Object.entries(batches).forEach(([batchKey, batch]) => {
//         const numVisitors = batch.queueIds.length - 1; // Exclude "empty"
//         if (numVisitors > 0) {
//           totalVisitors += numVisitors;
//           totalQueueTime += (batch.endAt - batch.startAt) * numVisitors;
//           batchCount++;

//           // Check for the busiest batch
//           if (numVisitors > maxVisitorsInBatch) {
//             maxVisitorsInBatch = numVisitors;
//             busiestBatchStartTime = batch.startAt;
//           }
//         }
//       });

//       const averageQueueTime =
//         totalVisitors > 0 ? totalQueueTime / totalVisitors : 0;

//       // Save analytics to Firestore
//       promises.push(
//         firestore
//           .collection("rideAnalytics")
//           .doc(rideId)
//           .set(
//             {
//               [todayKey]: {
//                 totalVisitors,
//                 averageQueueTime,
//                 totalQueueTime,
//                 batchCount,
//                 busiestBatchStartTime,
//                 rideStatus: rideData.status,
//                 createdAt: rideData.createdAt,
//               },
//             },
//             { merge: true }
//           )
//           .then(async () => {
//             // Remove batches from Realtime Database
//             await db.ref(`rides/${rideId}/batches`).remove();
//             console.log(`Archived and cleaned up batches for ride ${rideId}`);
//           })
//       );
//     });

//     await Promise.all(promises);
//     console.log("Batch cleanup and archival completed.");
//   });

/* eslint-disable @typescript-eslint/no-unused-vars */
import * as functions from "firebase-functions/v1";
import { getDatabase } from "./utils/database.js";
import admin from "firebase-admin";

export const generateDailyBatches = async () => {
  const db = getDatabase();
  const ridesRef = db.ref("rides");

  const ridesSnapshot = await ridesRef.once("value");
  let now = new Date(); // Current local time
  let today = new Date(); // Target day for batch generation

  // Determine the target date for batch generation
  if (
    now.getHours() >= 18 ||
    (now.getHours() < 10 && now.getDate() !== today.getDate())
  ) {
    // If after 6:01 PM or before 9:59 AM (next day), generate for the next day
    if (now.getHours() >= 18) {
      today.setDate(today.getDate() + 1); // Move to the next day if after 6:01 PM
    }
  }

  today.setHours(10, 0, 0, 0); // Start time: 10:00 AM (local time)

  const endHour = 18; // End time: 6 PM (local time)
  const promises = [];
  ridesSnapshot.forEach((rideSnapshot) => {
    const ride = rideSnapshot.val();
    const duration = ride.numOfRidersAllowed <= 5 ? 5 : 10; // Batch duration in minutes
    const batches = {};

    for (let hour = 10; hour < endHour; hour++) {
      for (let minute = 0; minute < 60; minute += duration) {
        const startAt = new Date(
          today.getTime() + (hour - 10) * 3600000 + minute * 60000
        );
        const endAt = new Date(startAt.getTime() + duration * 60000);

        // Ensure batch does not exceed 6 PM
        if (startAt.getHours() >= 18) break;

        // Generate the batch key in local time
        const batchKey = `${startAt.getFullYear()}-${(startAt.getMonth() + 1)
          .toString()
          .padStart(2, "0")}-${startAt
          .getDate()
          .toString()
          .padStart(2, "0")}T${startAt
          .getHours()
          .toString()
          .padStart(2, "0")}-${startAt
          .getMinutes()
          .toString()
          .padStart(2, "0")}-00`;

        // Save timestamps as local time in milliseconds
        batches[batchKey] = {
          startAt: startAt.getTime(), // Local time in milliseconds
          endAt: endAt.getTime(), // Local time in milliseconds
          queueIds: ["empty"],
          batchStatus: "pending",
          completedAt: 0,
          queueFilledAt: "Not Filled Up",
        };
      }
    }

    const batchPath = `rides/${rideSnapshot.key}/batches`;
    promises.push(
      db
        .ref(batchPath)
        .set(batches)
        .then(() => {
          console.log(`Batches generated for ride ${rideSnapshot.key}`);
        })
    );
  });

  await Promise.all(promises);
  console.log("Daily batch generation completed in local time.");
};

export const cleanupAndArchiveBatches = async () => {
  const db = getDatabase();
  const firestore = admin.firestore();
  const ridesRef = db.ref("rides");

  const now = new Date();
  const todayKey = now.toISOString().split("T")[0]; // e.g., "2024-12-25"

  const ridesSnapshot = await ridesRef.once("value");
  const rides = ridesSnapshot.val(); // Convert snapshot to an object

  if (!rides) {
    console.log("No rides found in the database.");
    return;
  }

  const promises = [];

  for (const [rideId, rideData] of Object.entries(rides)) {
    const rideName = rideData.name?.replace(/[^a-zA-Z0-9_-]/g, "_"); // Sanitize ride name

    if (!rideName) {
      console.error(`Ride ${rideId} has no valid name. Skipping.`);
      continue;
    }

    const batchesSnapshot = await db
      .ref(`rides/${rideId}/batches`)
      .once("value");
    const batches = batchesSnapshot.val();

    if (!batches) {
      console.log(`No batches found for ride ${rideId}. Logging as N/A.`);
      promises.push(
        firestore
          .collection("rideAnalytics")
          .doc(`${rideName}_${todayKey}`)
          .set(
            {
              [todayKey]: {
                totalVisitors: 0,
                averageQueueTime: "N/A",
                totalQueueTime: "N/A",
                batchCount: 0,
                nonCompletedBatchCount: 0,
                nonCompletedBatchTimes: [],
                busiestBatchStartTime: "N/A",
                rideStatus: rideData.status,
                createdAt: rideData.createdAt,
                operatorDelay: "N/A",
                notes:
                  "N/A (ride was likely closed when analytics was generated)",
              },
            },
            { merge: true }
          )
      );
      continue;
    }

    // Initialize analytics fields
    let totalVisitors = 0;
    let totalQueueTime = 0;
    let batchCount = 0;
    let nonCompletedBatchCount = 0;
    let nonCompletedBatchTimes = [];
    let busiestBatchStartTime = null;
    let maxVisitorsInBatch = 0;
    let operatorDelay = 0;

    Object.entries(batches).forEach(([batchKey, batch]) => {
      const numVisitors = Array.isArray(batch.queueIds)
        ? batch.queueIds.length - 1 // Exclude "empty"
        : 0;

      const validTimeTakenToComplete =
        batch.timeTakenToComplete > 0
          ? batch.timeTakenToComplete
          : batch.endAt - batch.startAt;

      // Handle completedAt = 0
      if (batch.completedAt === 0) {
        nonCompletedBatchCount++;
        nonCompletedBatchTimes.push(batchKey); // Use batchKey as timestamp
        console.log(`Batch ${batchKey} marked as N/A for completion.`);
        return;
      }

      // Handle queueFilledAt = "Not Filled Up"
      if (batch.queueFilledAt === "Not Filled Up") {
        nonCompletedBatchCount++;
        nonCompletedBatchTimes.push(batchKey);
        console.log(`Batch ${batchKey} had queue status: Not Filled Up.`);
        return;
      }

      // Aggregate valid data for analytics
      totalVisitors += numVisitors;
      totalQueueTime += validTimeTakenToComplete * numVisitors;
      batchCount++;

      // Calculate operator delay
      const delay = batch.completedAt - batch.endAt;
      if (delay > 0) {
        operatorDelay += delay;
      }

      // Check for the busiest batch
      if (numVisitors > maxVisitorsInBatch) {
        maxVisitorsInBatch = numVisitors;
        busiestBatchStartTime = batch.startAt;
      }
    });

    // Calculate average queue time and operator delay
    const averageQueueTime =
      totalVisitors > 0 ? totalQueueTime / totalVisitors : "N/A";
    const averageOperatorDelay =
      operatorDelay > 0 && batchCount > 0 ? operatorDelay / batchCount : "N/A";

    // Save analytics to Firestore
    promises.push(
      firestore
        .collection("rideAnalytics")
        .doc(`${rideName}_${todayKey}`)
        .set(
          {
            [todayKey]: {
              totalVisitors,
              averageQueueTime,
              totalQueueTime,
              batchCount,
              nonCompletedBatchCount,
              nonCompletedBatchTimes,
              busiestBatchStartTime,
              rideStatus: rideData.status,
              createdAt: rideData.createdAt,
              operatorDelay: averageOperatorDelay,
            },
          },
          { merge: true }
        )
        .then(async () => {
          // Remove batches from Realtime Database
          await db.ref(`rides/${rideId}/batches`).remove();
          console.log(
            `Archived and cleaned up batches for ride ${rideName} on ${todayKey}`
          );
        })
    );
  }

  await Promise.all(promises);
  console.log("Batch cleanup and archival completed.");
};
