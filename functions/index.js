const functions = require('firebase-functions');
const admin = require('firebase-admin');

admin.initializeApp();

const db = admin.firestore();

/**
 * Send FCM push notification to a user.
 */
async function sendNotification(uid, title, body) {
  if (!uid) return;
  try {
    const userDoc = await db.collection('users').doc(uid).get();
    const token = userDoc.data()?.fcmToken;
    if (!token) return;
    await admin.messaging().send({
      token,
      notification: { title, body },
      data: { click_action: 'FLUTTER_NOTIFICATION_CLICK' },
    });
  } catch (e) {
    console.warn(`FCM send failed for ${uid}:`, e.message);
  }
}

/**
 * Triggered when an application status changes.
 * - 'pending': tenant applied → notify caretaker
 * - 'approved'/'accepted': approved → notify tenant
 * - 'countered': caretaker countered → notify tenant
 */
exports.onApplicationStatusChange = functions.firestore
  .document('applications/{appId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return;
    if (before.status === after.status) return;

    const { unitId, tenantId, caretakerId, tenantName } = after;

    switch (after.status) {
      case 'pending':
        await sendNotification(
          caretakerId,
          'New Application',
          `${tenantName || 'A tenant'} applied for unit ${unitId || ''}`
        );
        break;

      case 'approved':
        await sendNotification(
          tenantId,
          'Application Approved',
          `Your application for unit ${unitId || ''} has been approved!`
        );
        break;

      case 'accepted':
        await sendNotification(
          caretakerId,
          'Offer Accepted',
          `${tenantName || 'Tenant'} accepted your counter-offer for unit ${unitId || ''}`
        );
        break;

      case 'countered': {
        const counterRent = after.caretakerCounterRent || '';
        await sendNotification(
          tenantId,
          'Counter Offer',
          `CareTaker proposed KES ${counterRent}/mo for unit ${unitId || ''}`
        );
        break;
      }

      case 'rejected':
        await sendNotification(
          tenantId,
          'Application Not Approved',
          `Your application for unit ${unitId || ''} was not approved.`
        );
        break;
    }
  });

/**
 * Triggered when a maintenance ticket status changes.
 */
exports.onMaintenanceStatusChange = functions.firestore
  .document('maintenance/{ticketId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (!before || !after) return;
    if (before.status === after.status) return;

    const { unitId, tenantId, issue } = after;

    if (after.status === 'resolved') {
      await sendNotification(
        tenantId,
        'Issue Resolved',
        `"${issue || 'Maintenance issue'}" has been resolved.`
      );
    } else if (after.status === 'in_progress') {
      await sendNotification(
        tenantId,
        'Issue In Progress',
        `"${issue || 'Maintenance issue'}" is being worked on.`
      );
    }
  });
