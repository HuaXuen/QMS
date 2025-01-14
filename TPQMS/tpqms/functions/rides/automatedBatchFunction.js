/* eslint-disable @typescript-eslint/no-unused-vars */
import * as functions from "firebase-functions/v1";
import { getDatabase } from "./utils/database.js";
import admin from "firebase-admin";

export const generateDailyBatches = async () => {
  const db = getDatabase();
  const ridesRef = db.ref("rides");

  const ridesSnapshot = await ridesRef.once("value");
  let now = new Date(); //Current local time
  let today = new Date(); //Target day for batch generation

  if (now.getHours() >= 10) {
    //After 6 PM, generate for next day
    today.setDate(today.getDate() + 1);
  } else {
    //Between 10 AM and 6 PM, generate for next day
    today.setDate(today.getDate());
  }

  today.setHours(10, 0, 0, 0); //Start time: 10:00 AM (local time)
  const endHour = 18; //End time: 6 PM (local time) 18
  const promises = [];
  ridesSnapshot.forEach((rideSnapshot) => {
    const ride = rideSnapshot.val();
    const duration = ride.numOfRidersAllowed <= 5 ? 5 : 10; //Batch duration in minutes
    const batches = {};

    for (let hour = 10; hour < endHour; hour++) {
      for (let minute = 0; minute < 60; minute += duration) {
        const startAt = new Date(
          today.getTime() + (hour - 10) * 3600000 + minute * 60000
        );
        const endAt = new Date(startAt.getTime() + duration * 60000);

        //Ensure batch does not exceed 6 PM
        if (startAt.getHours() >= 18) break;

        //Generate the batch key in local time
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

        //Save key as timestamps
        batches[batchKey] = {
          startAt: startAt.getTime(),
          endAt: endAt.getTime(),
          queueIds: ["empty"],
          batchStatus: "pending",
          completedAt: 0,
          queueFilledAt: "Not Filled Up",
          completedBy: null,
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

    // Initialize analytics metrics with operator tracking
    let analyticsData = {
      timeOfReportGeneration: reportGenerationTime,
      totalVisitors: 0,
      averageQueueTime: "N/A",
      nonCompletedBatchCount: 0,
      nonCompletedBatchTimes: [],
      nonFilledBatchCount: 0,
      nonFilledBatchIds: [],
      busiestBatchStartTime: "N/A",
      rideStatus: rideData.status || "unknown",
      fastestCompletionTime: null,
      // Enhanced operator tracking
      operators: new Set(),
      operatorStats: {}, // Will track stats per operator
      batchStatusSummary: {
        pending: 0,
        completed: 0,
        failed: 0,
        other: 0,
        statusList: [],
      },
    };

    if (!batches) {
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
      // Track operator activity
      if (batch.completedBy) {
        analyticsData.operators.add(batch.completedBy);

        // Initialize operator stats if not exists
        if (!analyticsData.operatorStats[batch.completedBy]) {
          analyticsData.operatorStats[batch.completedBy] = {
            batchesCompleted: 0,
            totalVisitorsProcessed: 0,
            averageCompletionTime: 0,
            totalCompletionTime: 0,
          };
        }
        if (batch.averageWaitTime && batch.queueIds) {
          const visitorCount = batch.queueIds.filter(
            (id) => id !== "empty"
          ).length;
          totalQueueTime += batch.averageWaitTime * visitorCount;
          totalProcessedVisitors += visitorCount;
        }

        // Update operator stats
        const operatorStats = analyticsData.operatorStats[batch.completedBy];
        operatorStats.batchesCompleted++;
        const visitorCount = batch.queueIds.filter(
          (id) => id !== "empty"
        ).length;
        operatorStats.totalVisitorsProcessed += visitorCount;

        if (batch.completedAt && batch.startAt) {
          const completionTime = batch.completedAt - batch.startAt;
          operatorStats.totalCompletionTime += completionTime;
          operatorStats.averageCompletionTime =
            operatorStats.totalCompletionTime / operatorStats.batchesCompleted;
        }
      }

      // Track batch statuses with enhanced details
      const batchStatusEntry = {
        batchKey: batchKey,
        status: batch.batchStatus || "unknown",
        completedBy: batch.completedBy || null,
        completionTime: batch.completedAt
          ? batch.completedAt - batch.startAt
          : null,
        visitorCount: batch.queueIds.filter((id) => id !== "empty").length,
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

      function formatBatchTime(timestamp) {
        // Create a date object from the timestamp
        const date = new Date(timestamp);

        // Get hours and minutes
        let hours = date.getUTCHours();
        const minutes = date.getUTCMinutes();

        // Convert to 12-hour format
        const period = hours >= 12 ? "PM" : "AM";
        hours = hours % 12;
        hours = hours ? hours : 12; // Convert 0 to 12

        // Pad minutes with leading zero if needed
        const minutesPadded = minutes.toString().padStart(2, "0");

        // Return formatted time string
        return `${hours}:${minutesPadded} ${period}`;
      }

      // Continue with existing analytics calculations...
      const visitorCount = Array.isArray(batch.queueIds)
        ? batch.queueIds.filter((id) => id !== "empty").length
        : 0;
      analyticsData.totalVisitors += visitorCount;

      if (batch.completedAt === 0) {
        analyticsData.nonCompletedBatchCount++;
        const batchTime = formatBatchTime(batch.startAt);
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
          fastestBatchStartTime = formatBatchTime(batch.startAt);
        }

        totalQueueTime += completionTime;
        totalProcessedVisitors += visitorCount;
      }
    });

    // Convert Set to Array and finalize analytics
    analyticsData.operators = Array.from(analyticsData.operators);
    analyticsData.busiestBatchStartTime = fastestBatchStartTime || "N/A";
    analyticsData.averageQueueTime =
      totalProcessedVisitors > 0
        ? `${Math.round(
            totalQueueTime / totalProcessedVisitors / 1000 / 60
          )} minutes`
        : "N/A";

    // Save analytics and cleanup
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
    // Define multiple operators including the provided adminId
    const operators = [
      adminId,
      "operator_" + nanoid(6),
      "operator_" + nanoid(6),
      "operator_" + nanoid(6),
    ];

    // Set up time range (10 AM to 6 PM on January 14th, 2025)
    const baseDate = new Date("2025-01-14T10:00:00");
    const endTime = new Date("2025-01-14T18:00:00");
    const batchInterval = 10 * 60 * 1000; // 10 minutes in milliseconds

    const batches = {};
    const currentTime = new Date(baseDate);

    // Helper function to determine visitors based on time of day
    function getVisitorCountForTime(hour) {
      if (hour >= 11 && hour < 14) {
        // Peak hours: 11 AM - 2 PM (7-10 visitors)
        return Math.floor(Math.random() * 4) + 7;
      } else if (hour >= 14 && hour < 16) {
        // High traffic: 2 PM - 4 PM (5-9 visitors)
        return Math.floor(Math.random() * 5) + 5;
      } else {
        // Normal hours: 10-11 AM and 4-6 PM (3-5 visitors)
        return Math.floor(Math.random() * 3) + 3;
      }
    }

    // Generate batches with 100% completion rate
    while (currentTime < endTime) {
      const batchKey = currentTime
        .toISOString()
        .replace(/\.\d+Z$/, "")
        .replace(/:/g, "-")
        .slice(0, 19);

      const hour = currentTime.getHours();
      const visitorCount = getVisitorCountForTime(hour);
      const queueIds = Array.from({ length: visitorCount }, () => nanoid());
      if (queueIds.length === 0) queueIds.push("empty");

      const startAt = currentTime.getTime();
      const endAt = startAt + batchInterval;

      // All batches are completed (100% completion rate)
      const completedAt = endAt + Math.random() * 60000; // Random completion time within 1 minute after endAt

      // Assign a random operator for all batches (since all are completed)
      const assignedOperator =
        operators[Math.floor(Math.random() * operators.length)].toString();

      batches[batchKey] = {
        startAt,
        endAt,
        queueIds,
        batchStatus: "completed", // Always completed
        completedAt,
        queueFilledAt:
          queueIds.length >= 10
            ? new Date(startAt - Math.random() * 300000).toISOString() // Random time before batch start
            : "Not Filled Up",
        completedBy: assignedOperator,
      };

      currentTime.setTime(currentTime.getTime() + batchInterval);
    }

    // Save batches to database
    await db.ref(`rides/${rideId}/batches`).set(batches);
    console.log(
      `Generated ${
        Object.keys(batches).length
      } batches for ride ${rideId} with ${operators.length} operators`
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
