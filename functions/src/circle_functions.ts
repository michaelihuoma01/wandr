// functions/src/circle_functions.ts
import { onDocumentCreated, onDocumentUpdated } from 'firebase-functions/v2/firestore';
import { onCall } from 'firebase-functions/v2/https';
import { onSchedule } from 'firebase-functions/v2/scheduler';
import * as admin from 'firebase-admin';

const db = admin.firestore();
const fcm = admin.messaging();

// Circle Activity Notifications
export const onCircleActivity = onDocumentCreated({document: 'circles/{circleId}/activity/{activityId}'},
  async (event) => {
    const snapshot = event.data;
    if (!snapshot) {
      console.log('No data associated with the event');
      return;
    }

    const activity = snapshot.data();
    const { circleId, activityId } = event.params;

    try {
      // Get circle info
      const circleDoc = await db.collection('circles').doc(circleId).get();
      if (!circleDoc.exists) return;
      
      const circle = circleDoc.data()!;

       // Don't notify for reactions or comments on own activity
    if (activity.type === 'reaction' || activity.type === 'comment') {
      const targetActivityDoc = await db
        .collection('circles')
        .doc(circleId)
        .collection('activity')
        .doc(activity.data.activityId)
        .get();
      
      if (targetActivityDoc.exists && targetActivityDoc.data()?.userId === activity.userId) {
        return; // Don't notify users of reactions/comments on their own posts
      }
    }

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
  }
);

// Process Join Requests
export const processJoinRequest = onCall({cors: true},
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new Error('User must be authenticated');
    }

    const { circleId, userId, approve } = request.data;

    try {
      // Verify the caller is an admin
      const memberDoc = await db
        .collection('circles')
        .doc(circleId)
        .collection('members')
        .doc(auth.uid)
        .get();

      if (!memberDoc.exists || memberDoc.data()?.role !== 'admin') {
        throw new Error('Only admins can process join requests');
      }

      // Get the join request
      const requestRef = db
        .collection('circles')
        .doc(circleId)
        .collection('joinRequests')
        .doc(userId);

      const requestDoc = await requestRef.get();
      if (!requestDoc.exists) {
        throw new Error('Join request not found');
      }

      const joinRequest = requestDoc.data()!;

      if (approve) {
        // Add user as member
        const batch = db.batch();

        // Add to circle members
        batch.set(
          db.collection('circles').doc(circleId).collection('members').doc(userId),
          {
            userId,
            userName: joinRequest.userName,
            userPhotoUrl: joinRequest.userPhotoUrl,
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
          processedBy: auth.uid,
        });

        await batch.commit();

        // Send notification to user
        await sendNotificationToUser(userId, {
          title: 'Join Request Approved!',
          body: `You've been accepted into ${joinRequest.circleName}`,
          type: 'join_approved',
          circleId,
        });
      } else {
        // Reject request
        await requestRef.update({
          status: 'rejected',
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          processedBy: auth.uid,
        });
      }

      return { success: true };
    } catch (error) {
      console.error('Error processing join request:', error);
      throw new Error('Failed to process request');
    }
  }
);

// Aggregate Circle Places
export const aggregateCirclePlaces = onSchedule(
  {schedule: 'every 6 hours'},
  async (event) => {
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
  }
);

// Calculate Vibe Compatibility
export const calculateVibeCompatibility = onCall(
  {
    cors: true,
  },
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new Error('User must be authenticated');
    }

    const userId = auth.uid;

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
      throw new Error('Failed to calculate compatibility');
    }
  }
);

// Circle Insights (Analytics)
export const generateCircleInsights = onSchedule(
  {
    schedule: 'every sunday 00:00',
    timeZone: 'America/New_York', // Adjust as needed
  },
  async (event) => {
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

        // Find most active members
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
  }
);

// Add new function for push notification setup:
export const setupUserNotifications = onCall(
  {
    cors: true,
  },
  async (request) => {
    const auth = request.auth;
    if (!auth) {
      throw new Error('User must be authenticated');
    }

    const { fcmToken } = request.data;

    try {
      await db.collection('users').doc(auth.uid).update({
        fcmTokens: admin.firestore.FieldValue.arrayUnion(fcmToken),
        lastTokenUpdate: admin.firestore.FieldValue.serverTimestamp(),
        notificationsEnabled: true,
      });

      return { success: true };
    } catch (error) {
      console.error('Error setting up notifications:', error);
      throw new Error('Failed to setup notifications');
    }
  }
);

export const onActivityInteraction = onDocumentUpdated(
  {document: 'circles/{circleId}/activity/{activityId}'},
  async (event) => {
    const before = event.data?.before.data();
    const after = event.data?.after.data();
    
    if (!before || !after) return;
    
    const { circleId, activityId } = event.params;
    
    // Check for new reactions
    const beforeReactions = before.reactions || {};
    const afterReactions = after.reactions || {};
    
    for (const [emoji, users] of Object.entries(afterReactions)) {
      const beforeUsers = beforeReactions[emoji] || [];
      const newUsers = (users as string[]).filter(u => !beforeUsers.includes(u));
      
      for (const userId of newUsers) {
        // Don't notify the activity creator if they react to their own post
        if (userId === after.userId) continue;
        
        // Send notification to activity creator
        await sendReactionNotification(
          circleId,
          activityId,
          after.userId, // activity creator
          userId, // reactor
          emoji
        );
      }
    }
    
    // Check for new comments
    const beforeComments = before.comments || [];
    const afterComments = after.comments || [];
    
    if (afterComments.length > beforeComments.length) {
      const newComment = afterComments[afterComments.length - 1];
      
      // Don't notify if commenting on own post
      if (newComment.userId !== after.userId) {
        await sendCommentNotification(
          circleId,
          activityId,
          after.userId, // activity creator
          newComment
        );
      }
    }
  }
);

async function sendReactionNotification(
  circleId: string,
  activityId: string,
  activityUserId: string,
  reactorId: string,
  emoji: string
) {
  try {
    // Get reactor info
    const reactorDoc = await db.collection('users').doc(reactorId).get();
    const reactorName = reactorDoc.data()?.displayName || 'Someone';
    
    // Get circle info
    const circleDoc = await db.collection('circles').doc(circleId).get();
    const circleName = circleDoc.data()?.name || 'Circle';
    
    // Create notification
    await db.collection('notifications')
      .doc(activityUserId)
      .collection('circle_notifications')
      .add({
        type: 'reaction',
        circleId,
        circleName,
        activityId,
        title: `New reaction in ${circleName}`,
        body: `${reactorName} reacted ${emoji} to your post`,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          reactorId,
          emoji,
        },
      });
    
    // Send push notification
    const userDoc = await db.collection('users').doc(activityUserId).get();
    if (userDoc.exists && userDoc.data()?.fcmTokens) {
      const tokens = userDoc.data()!.fcmTokens;
      
      await fcm.sendMulticast({
        tokens,
        notification: {
          title: `New reaction in ${circleName}`,
          body: `${reactorName} reacted ${emoji} to your post`,
        },
        data: {
          type: 'reaction',
          circleId,
          activityId,
        },
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
      });
    }
  } catch (error) {
    console.error('Error sending reaction notification:', error);
  }
}

async function sendCommentNotification(
  circleId: string,
  activityId: string,
  activityUserId: string,
  comment: any
) {
  try {
    // Get circle info
    const circleDoc = await db.collection('circles').doc(circleId).get();
    const circleName = circleDoc.data()?.name || 'Circle';
    
    // Create notification
    await db.collection('notifications')
      .doc(activityUserId)
      .collection('circle_notifications')
      .add({
        type: 'comment',
        circleId,
        circleName,
        activityId,
        title: `New comment in ${circleName}`,
        body: `${comment.userName} commented: "${comment.text.substring(0, 50)}${comment.text.length > 50 ? '...' : ''}"`,
        isRead: false,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        data: {
          commenterId: comment.userId,
          commentText: comment.text,
        },
      });
    
    // Send push notification
    const userDoc = await db.collection('users').doc(activityUserId).get();
    if (userDoc.exists && userDoc.data()?.fcmTokens) {
      const tokens = userDoc.data()!.fcmTokens;
      
      await fcm.sendMulticast({
        tokens,
        notification: {
          title: `New comment in ${circleName}`,
          body: `${comment.userName}: ${comment.text.substring(0, 50)}${comment.text.length > 50 ? '...' : ''}`,
        },
        data: {
          type: 'comment',
          circleId,
          activityId,
        },
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
      });
    }
  } catch (error) {
    console.error('Error sending comment notification:', error);
  }
}

// Helper Functions
function getNotificationTitle(activityType: string, circleName: string): string {
  const titles: Record<string, string> = {
    checkIn: `New check-in in ${circleName}`,
    placeShared: `New place shared in ${circleName}`,
    boardCreated: `New vibe board in ${circleName}`,
    microReview: `New review in ${circleName}`,
    memberJoined: `New member joined ${circleName}`,
    milestone: `${circleName} milestone!`,
    reaction: `New reaction in ${circleName}`, // ADD
    comment: `New comment in ${circleName}`, // ADD
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
    reaction: `${activity.userName} reacted to your post`, // ADD
    comment: `${activity.userName} commented on your post`, // ADD
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
  onActivityInteraction,
  setupUserNotifications
};