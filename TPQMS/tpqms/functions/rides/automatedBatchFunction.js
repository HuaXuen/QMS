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

  // Revised date logic
  if (now.getHours() >= 18) {
    // After 6 PM, generate for next day
    today.setDate(today.getDate());
    // Before 10 AM, generate for current day
    // No date adjustment needed since we want today's batches
  } else {
    // Between 10 AM and 6 PM, generate for next day
    today.setDate(today.getDate());
  }

  today.setHours(16, 0, 0, 0); // Start time: 10:00 AM (local time)

  const endHour = 23; // End time: 6 PM (local time) 18 i changed to 23
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

        // Ensure batch does not exceed 6 PM 18 i changed to 23
        if (startAt.getHours() >= 23) break;

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

  const reportGenerationTime = new Date().toLocaleString("en-US", {
    hour: "numeric",
    minute: "2-digit",
    hour12: true,
    timeZone: "Asia/Kuala_Lumpur",
    day: "2-digit",
    month: "short",
    year: "numeric",
  });

  const now = new Date();
  const todayKey = now.toISOString().split("T")[0];

  const ridesSnapshot = await ridesRef.once("value");
  const rides = ridesSnapshot.val();

  if (!rides) {
    console.log("No rides found in the database.");
    return;
  }

  const promises = [];

  for (const [rideId, rideData] of Object.entries(rides)) {
    const rideName = rideData.name?.replace(/[^a-zA-Z0-9_-]/g, "_");

    if (!rideName) {
      console.error(`Ride ${rideId} has no valid name. Skipping.`);
      continue;
    }

    const batchesSnapshot = await db
      .ref(`rides/${rideId}/batches`)
      .once("value");
    const batches = batchesSnapshot.val();

    // Initialize analytics metrics
    let analyticsData = {
      timeOfReportGeneration: reportGenerationTime, // e.g. "Dec 23, 2024, 10:30 PM"
      totalVisitors: 0,
      averageQueueTime: "N/A",
      nonCompletedBatchCount: 0,
      nonCompletedBatchTimes: [],
      nonFilledBatchCount: 0,
      nonFilledBatchIds: [],
      busiestBatchStartTime: "N/A",
      rideStatus: rideData.status || "unknown",
      fastestCompletionTime: null,
      // New fields for operators and batch statuses
      operators: new Set(), // We'll convert this to array later
      batchStatusSummary: {
        pending: 0,
        completed: 0,
        failed: 0,
        other: 0,
        statusList: [], // Will store all batch statuses with their timestamps
      },
    };

    if (!batches) {
      // Convert Set to Array before saving
      analyticsData.operators = Array.from(analyticsData.operators);
      promises.push(
        firestore
          .collection("rideAnalytics")
          .doc(`${rideName}_${todayKey}`)
          .set({ [todayKey]: analyticsData }, { merge: true })
      );
      continue;
    }

    let totalQueueTime = 0;
    let totalProcessedVisitors = 0;
    let fastestCompletionTime = Infinity;
    let fastestBatchStartTime = null;

    Object.entries(batches).forEach(([batchKey, batch]) => {
      // Track batch statuses with original batch keys
      const batchStatusEntry = {
        batchKey: batchKey, // Original batch key e.g. "2025-01-01T13-00-00"
        status: batch.batchStatus || "unknown",
        completedBy: batch.completedBy || null, // Include operator ID if available
      };
      analyticsData.batchStatusSummary.statusList.push(batchStatusEntry);

      // Update batch status counts
      switch (batch.batchStatus?.toLowerCase()) {
        case "pending":
          analyticsData.batchStatusSummary.pending++;
          break;
        case "completed":
          analyticsData.batchStatusSummary.completed++;
          break;
        case "failed":
          analyticsData.batchStatusSummary.failed++;
          break;
        default:
          analyticsData.batchStatusSummary.other++;
      }

      // Existing analytics calculations
      const visitorCount = Array.isArray(batch.queueIds)
        ? batch.queueIds.filter((id) => id !== "empty").length
        : 0;
      analyticsData.totalVisitors += visitorCount;

      if (batch.completedAt === 0) {
        analyticsData.nonCompletedBatchCount++;
        const batchTime = new Date(batch.startAt).toLocaleString("en-US", {
          hour: "numeric",
          minute: "2-digit",
          hour12: true,
          timeZone: "Asia/Kuala_Lumpur",
        });
        analyticsData.nonCompletedBatchTimes.push(batchTime);
      }

      if (batch.queueFilledAt === "Not Filled Up") {
        analyticsData.nonFilledBatchCount++;
        analyticsData.nonFilledBatchIds.push(batchKey);
      }

      if (batch.completedAt && batch.completedAt !== 0) {
        const completionTime = batch.completedAt - batch.startAt;
        if (completionTime < fastestCompletionTime) {
          fastestCompletionTime = completionTime;
          fastestBatchStartTime = new Date(batch.startAt).toLocaleString(
            "en-US",
            {
              hour: "numeric",
              minute: "2-digit",
              hour12: true,
              timeZone: "Asia/Kuala_Lumpur",
            }
          );
        }

        totalQueueTime += completionTime;
        totalProcessedVisitors += visitorCount;
      }
    });

    // Convert Set to Array before saving
    analyticsData.operators = Array.from(analyticsData.operators);

    analyticsData.busiestBatchStartTime = fastestBatchStartTime || "N/A";
    analyticsData.averageQueueTime =
      totalProcessedVisitors > 0
        ? `${Math.round(
            totalQueueTime / totalProcessedVisitors / 1000 / 60
          )} minutes`
        : "N/A";

    promises.push(
      Promise.all([
        firestore
          .collection("rideAnalytics")
          .doc(`${rideName}_${todayKey}`)
          .set({ [todayKey]: analyticsData }, { merge: true }),

        db.ref(`rides/${rideId}/batches`).remove(),
      ])
    );

    console.log(`Processed analytics for ride: ${rideName}`);
  }

  await Promise.all(promises);
  console.log("Batch cleanup and analytics archival completed.");
};

import { nanoid } from "nanoid/non-secure";

export async function generateDummyBatchData(rideId, adminId) {
  const db = getDatabase();

  try {
    // Set up time range for January 4th, 2025 (10 AM to 11 PM)
    const baseDate = new Date("2025-01-03T10:00:00");
    const endTime = new Date("2025-01-03T23:00:00");
    const batchInterval = 10 * 60 * 1000; // 10 minutes in milliseconds

    const batches = {};
    const currentTime = new Date(baseDate);

    // Helper function to determine visitors based on time of day
    function getVisitorCountForTime(hour) {
      // Peak hours (12 PM - 4 PM)
      if (hour >= 12 && hour < 16) {
        return Math.floor(Math.random() * 4) + 7; // 7-10 visitors
      }
      // High traffic (4 PM - 8 PM)
      else if (hour >= 16 && hour < 20) {
        return Math.floor(Math.random() * 4) + 6; // 6-9 visitors
      }
      // Morning/Late Night (10 AM - 12 PM, 8 PM - 11 PM)
      else {
        return Math.floor(Math.random() * 4) + 3; // 3-6 visitors
      }
    }

    // Helper function to determine if batch should be completed (90% chance)
    function shouldComplete() {
      return Math.random() < 0.9;
    }

    // Generate batches
    while (currentTime < endTime) {
      const batchKey = currentTime
        .toISOString()
        .replace(/\.\d+Z$/, "")
        .replace(/:/g, "-")
        .slice(0, 19);

      const hour = currentTime.getHours();
      const visitorCount = getVisitorCountForTime(hour);

      // Generate unique IDs for visitors
      const queueIds = Array.from({ length: visitorCount }, () => nanoid());
      if (queueIds.length === 0) queueIds.push("empty");

      const startAt = currentTime.getTime();
      const endAt = startAt + batchInterval;

      // Determine if batch should be completed
      const isCompleted = shouldComplete();
      const completedAt = isCompleted ? endAt + Math.random() * 60000 : 0; // Random completion time within 1 minute after endAt

      batches[batchKey] = {
        startAt,
        endAt,
        queueIds,
        batchStatus: isCompleted ? "completed" : "pending",
        completedAt: completedAt,
        queueFilledAt:
          queueIds.length >= 10
            ? new Date(startAt - Math.random() * 300000).toISOString() // Random time within 5 minutes before start
            : "Not Filled Up",
        completedBy: isCompleted ? adminId : null,
      };

      currentTime.setTime(currentTime.getTime() + batchInterval);
    }

    // Save batches to database
    await db.ref(`rides/${rideId}/batches`).set(batches);
    console.log(
      `Generated ${Object.keys(batches).length} batches for ride ${rideId}`
    );
    return batches;
  } catch (error) {
    console.error("Error generating dummy batch data:", error);
    throw error;
  }
}
// Example usage:
/*
const dummyBatches = await generateDummyBatchData(
  'ride123', 
  'AhHJrLqC2b3TqMHSOBAU'
);
console.log(JSON.stringify(dummyBatches, null, 2));
*/
