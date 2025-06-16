// functions/src/circle_functions.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const fcm = admin.messaging();

// Circle Activity Notifications
export const onCircleActivity = functions.firestore
  .document('circles/{circleId}/activity/{activityId}')
  .onCreate(async (snap: functions.firestore.QueryDocumentSnapshot, context: functions.EventContext) => {
    const activity = snap.data();
    const { circleId, activityId } = context.params;

    try {
      // Get circle info§§
      const circleDoc = await db.collection('circles').doc(circleId).get();
      if (!circleDoc.exists) return;
      
      const circle = circleDoc.data()!;

      // Get all circle members except the actor
      const membersSnapshot = await db
        .collection('circles')
        .doc(circleId)
        .collection('members')
        .where('notificationsEnabled', '==', true)
        .get();

      const notifications: Promise<any>[] = [];

      for (const memberDoc of membersSnapshot.docs) {
        const member = memberDoc.data();
        
        // Skip the actor
        if (member.userId === activity.userId) continue;

        // Create notification message
        const notification = {
          title: getNotificationTitle(activity.type, circle.name),
          body: getNotificationBody(activity, member.userName),
          data: {
            type: 'circle_activity',
            circleId,
            activityId,
            activityType: activity.type,
          },
        };

        // Save to user's notifications
        notifications.push(
          db.collection('notifications')
            .doc(member.userId)
            .collection('circle_notifications')
            .add({
              ...notification,
              circleId,
              circleName: circle.name,
              type: mapActivityToNotificationType(activity.type),
              isRead: false,
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
            })
        );

        // Get user's FCM tokens
        const userDoc = await db.collection('users').doc(member.userId).get();
        if (userDoc.exists && userDoc.data()?.fcmTokens) {
          const tokens = userDoc.data()!.fcmTokens;
          
          // Send push notification
          notifications.push(
            fcm.sendMulticast({
              tokens,
              notification: {
                title: notification.title,
                body: notification.body,
              },
              data: notification.data,
              android: {
                priority: 'high',
                notification: {
                  channelId: 'circle_activity',
                },
              },
              apns: {
                payload: {
                  aps: {
                    badge: 1,
                    sound: 'default',
                  },
                },
              },
            })
          );
        }
      }

      await Promise.all(notifications);
    } catch (error) {
      console.error('Error sending circle notifications:', error);
    }
  });

// Process Join Requests
export const processJoinRequest = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { circleId, userId, approve } = data;

  try {
    // Verify the caller is an admin
    const memberDoc = await db
      .collection('circles')
      .doc(circleId)
      .collection('members')
      .doc(context.auth.uid)
      .get();

    if (!memberDoc.exists || memberDoc.data()?.role !== 'admin') {
      throw new functions.https.HttpsError('permission-denied', 'Only admins can process join requests');
    }

    // Get the join request
    const requestRef = db
      .collection('circles')
      .doc(circleId)
      .collection('joinRequests')
      .doc(userId);

    const requestDoc = await requestRef.get();
    if (!requestDoc.exists) {
      throw new functions.https.HttpsError('not-found', 'Join request not found');
    }

    const request = requestDoc.data()!;

    if (approve) {
      // Add user as member
      const batch = db.batch();

      // Add to circle members
      batch.set(
        db.collection('circles').doc(circleId).collection('members').doc(userId),
        {
          userId,
          userName: request.userName,
          userPhotoUrl: request.userPhotoUrl,
          circleId,
          role: 'member',
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
          notificationsEnabled: true,
          contributionScore: 0,
          checkInsShared: 0,
          boardsCreated: 0,
          reviewsWritten: 0,
        }
      );

      // Add to user's circles
      batch.set(
        db.collection('users').doc(userId).collection('circles').doc(circleId),
        {
          joinedAt: admin.firestore.FieldValue.serverTimestamp(),
          role: 'member',
        }
      );

      // Update circle member count
      batch.update(db.collection('circles').doc(circleId), {
        memberCount: admin.firestore.FieldValue.increment(1),
      });

      // Update request status
      batch.update(requestRef, {
        status: 'approved',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        processedBy: context.auth.uid,
      });

      await batch.commit();

      // Send notification to user
      await sendNotificationToUser(userId, {
        title: 'Join Request Approved!',
        body: `You've been accepted into ${request.circleName}`,
        type: 'join_approved',
        circleId,
      });
    } else {
      // Reject request
      await requestRef.update({
        status: 'rejected',
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        processedBy: context.auth.uid,
      });
    }

    return { success: true };
  } catch (error) {
    console.error('Error processing join request:', error);
    throw new functions.https.HttpsError('internal', 'Failed to process request');
  }
});

// Aggregate Circle Places
export const aggregateCirclePlaces = functions.pubsub
  .schedule('every 6 hours')
  .onRun(async (context) => {
    try {
      const circlesSnapshot = await db.collection('circles').get();

      for (const circleDoc of circlesSnapshot.docs) {
        const circleId = circleDoc.id;
        
        // Get all members
        const membersSnapshot = await db
          .collection('circles')
          .doc(circleId)
          .collection('members')
          .get();

        const memberIds = membersSnapshot.docs.map(doc => doc.id);

        if (memberIds.length === 0) continue;

        // Get all visits from members
        const visitsSnapshot = await db
          .collection('visits')
          .where('userId', 'in', memberIds.slice(0, 10)) // Firestore 'in' limit
          .orderBy('visitTime', 'desc')
          .limit(100)
          .get();

        // Aggregate places
        const placeMap = new Map<string, any>();
        
        for (const visitDoc of visitsSnapshot.docs) {
          const visit = visitDoc.data();
          const placeKey = visit.placeId || `${visit.latitude},${visit.longitude}`;
          
          if (!placeMap.has(placeKey)) {
            placeMap.set(placeKey, {
              placeId: visit.placeId,
              placeName: visit.placeName,
              placeType: visit.placeType,
              latitude: visit.latitude,
              longitude: visit.longitude,
              visitCount: 0,
              lastVisit: visit.visitTime,
              vibes: new Set(),
              ratings: [],
            });
          }
          
          const place = placeMap.get(placeKey);
          place.visitCount++;
          place.lastVisit = visit.visitTime;
          
          if (visit.vibes) {
            visit.vibes.forEach((vibe: string) => place.vibes.add(vibe));
          }
          
          if (visit.rating) {
            place.ratings.push(visit.rating);
          }
        }

        // Save aggregated data
        const aggregatedPlaces = Array.from(placeMap.values()).map(place => ({
          ...place,
          vibes: Array.from(place.vibes),
          averageRating: place.ratings.length > 0 
            ? place.ratings.reduce((a: number, b: number) => a + b) / place.ratings.length 
            : null,
        }));

        await db.collection('circles').doc(circleId).update({
          aggregatedPlaces,
          lastAggregated: admin.firestore.FieldValue.serverTimestamp(),
        });
      }
    } catch (error) {
      console.error('Error aggregating circle places:', error);
    }
  });

// Calculate Vibe Compatibility
export const calculateVibeCompatibility = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const userId = context.auth.uid;

  try {
    // Get user's vibe preferences from visits
    const visitsSnapshot = await db
      .collection('visits')
      .where('userId', '==', userId)
      .orderBy('visitTime', 'desc')
      .limit(50)
      .get();

    const userVibes = new Map<string, number>();
    
    for (const visitDoc of visitsSnapshot.docs) {
      const visit = visitDoc.data();
      if (visit.vibes) {
        visit.vibes.forEach((vibe: string) => {
          userVibes.set(vibe, (userVibes.get(vibe) || 0) + 1);
        });
      }
    }

    // Sort vibes by frequency
    const sortedVibes = Array.from(userVibes.entries())
      .sort((a, b) => b[1] - a[1])
      .map(([vibe]) => vibe);

    if (sortedVibes.length === 0) {
      return { suggestions: [] };
    }

    // Find compatible circles
    const circlesSnapshot = await db
      .collection('circles')
      .where('isPublic', '==', true)
      .where('vibePreferences', 'array-contains-any', sortedVibes.slice(0, 5))
      .limit(20)
      .get();

    const suggestions = circlesSnapshot.docs.map(doc => {
      const circle = doc.data();
      const matchingVibes = circle.vibePreferences.filter((vibe: string) => 
        sortedVibes.includes(vibe)
      );
      
      const score = matchingVibes.length / circle.vibePreferences.length;
      
      return {
        circleId: doc.id,
        circle: {
          id: doc.id,
          ...circle,
        },
        compatibilityScore: score,
        matchingVibes,
        reason: `Matches ${matchingVibes.length} of your favorite vibes`,
      };
    });

    // Sort by compatibility score
    suggestions.sort((a, b) => b.compatibilityScore - a.compatibilityScore);

    return { suggestions: suggestions.slice(0, 10) };
  } catch (error) {
    console.error('Error calculating vibe compatibility:', error);
    throw new functions.https.HttpsError('internal', 'Failed to calculate compatibility');
  }
});

// Circle Insights (Analytics)
export const generateCircleInsights = functions.pubsub
  .schedule('every sunday 00:00')
  .onRun(async (context) => {
    try {
      const circlesSnapshot = await db.collection('circles').get();

      for (const circleDoc of circlesSnapshot.docs) {
        const circleId = circleDoc.id;
        const circle = circleDoc.data();

        // Get weekly activity
        const weekAgo = new Date();
        weekAgo.setDate(weekAgo.getDate() - 7);

        const activitySnapshot = await db
          .collection('circles')
          .doc(circleId)
          .collection('activity')
          .where('timestamp', '>=', weekAgo)
          .get();

        const memberActivityMap = new Map<string, number>();
        const activityByType = new Map<string, number>();

        activitySnapshot.docs.forEach(doc => {
          const activity = doc.data();
          
          // Count by member
          memberActivityMap.set(
            activity.userId,
            (memberActivityMap.get(activity.userId) || 0) + 1
          );
          
          // Count by type
          activityByType.set(
            activity.type,
            (activityByType.get(activity.type) || 0) + 1
          );
        });

        // Find most active member
        const mostActiveMembers = Array.from(memberActivityMap.entries())
          .sort((a, b) => b[1] - a[1])
          .slice(0, 3);

        // Generate insights
        const insights = {
          weeklyActivityCount: activitySnapshot.size,
          mostActiveMembers,
          activityBreakdown: Object.fromEntries(activityByType),
          generatedAt: admin.firestore.FieldValue.serverTimestamp(),
        };

        // Save insights
        await db
          .collection('circles')
          .doc(circleId)
          .collection('insights')
          .add(insights);

        // Send weekly digest to members
        if (circle.sendWeeklyDigest) {
          await sendWeeklyDigest(circleId, insights);
        }
      }
    } catch (error) {
      console.error('Error generating circle insights:', error);
    }
  });

// Helper Functions
function getNotificationTitle(activityType: string, circleName: string): string {
  const titles: Record<string, string> = {
    checkIn: `New check-in in ${circleName}`,
    placeShared: `New place shared in ${circleName}`,
    boardCreated: `New vibe board in ${circleName}`,
    microReview: `New review in ${circleName}`,
    memberJoined: `New member joined ${circleName}`,
    milestone: `${circleName} milestone!`,
  };
  return titles[activityType] || `Activity in ${circleName}`;
}

function getNotificationBody(activity: any, userName: string): string {
  const bodies: Record<string, string> = {
    checkIn: `${activity.userName} checked in at ${activity.data.placeName}`,
    placeShared: `${activity.userName} shared ${activity.data.placeName}`,
    boardCreated: `${activity.userName} created "${activity.data.boardTitle}"`,
    microReview: `${activity.userName} reviewed ${activity.data.placeName}`,
    memberJoined: `${activity.userName} joined the circle`,
    milestone: activity.data.message || 'Circle milestone achieved!',
  };
  return bodies[activity.type] || 'New activity in your circle';
}

function mapActivityToNotificationType(activityType: string): string {
  const mapping: Record<string, string> = {
    checkIn: 'newCheckIn',
    placeShared: 'newCheckIn',
    boardCreated: 'newBoard',
    microReview: 'newReview',
    memberJoined: 'newMember',
    milestone: 'milestone',
  };
  return mapping[activityType] || 'newCheckIn';
}

async function sendNotificationToUser(
  userId: string, 
  notification: {
    title: string;
    body: string;
    type: string;
    circleId: string;
  }
) {
  try {
    // Get user's FCM tokens
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists || !userDoc.data()?.fcmTokens) return;

    const tokens = userDoc.data()!.fcmTokens;
    
    await fcm.sendMulticast({
      tokens,
      notification: {
        title: notification.title,
        body: notification.body,
      },
      data: {
        type: notification.type,
        circleId: notification.circleId,
      },
    });
  } catch (error) {
    console.error('Error sending notification to user:', error);
  }
}

async function sendWeeklyDigest(circleId: string, insights: any) {
  // Implementation for weekly digest emails
  // This would integrate with SendGrid or similar service
  console.log(`Sending weekly digest for circle ${circleId}`, insights);
}

// Export functions
export const circleNotifications = {
  onCircleActivity,
  processJoinRequest,
  aggregateCirclePlaces,
  calculateVibeCompatibility,
  generateCircleInsights,
};