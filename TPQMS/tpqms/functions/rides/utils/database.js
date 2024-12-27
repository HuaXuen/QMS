import admin from "firebase-admin";

export function getDatabase() {
  if (!admin.apps.length) {
    admin.initializeApp();
  }
  return admin.database();
}
