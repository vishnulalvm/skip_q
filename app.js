// Utility Functions
function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).substr(2);
}

function formatTime(seconds) {
  if (seconds < 60) return `${seconds} seconds`;
  const minutes = Math.floor(seconds / 60);
  return `${minutes} minute${minutes > 1 ? 's' : ''}`;
}

function getQueueUrl(queueId) {
  const baseUrl = window.location.origin + window.location.pathname.replace(/[^/]*$/, '');
  return `${baseUrl}join.html?queueId=${queueId}`;
}

// Queue Management Functions
async function createQueue(queueName) {
  try {
    const queueId = generateId();
    const queueData = {
      name: queueName,
      createdAt: firebase.firestore.FieldValue.serverTimestamp(),
      currentToken: 0,
      totalServed: 0,
      averageServeTime: 120, // Default 2 minutes
      status: 'active'
    };
    
    await db.collection('queues').doc(queueId).set(queueData);
    return queueId;
  } catch (error) {
    console.error('Error creating queue:', error);
    throw error;
  }
}

async function joinQueue(queueId, customerName, quantity) {
  try {
    // Get current queue data
    const queueDoc = await db.collection('queues').doc(queueId).get();
    if (!queueDoc.exists) {
      throw new Error('Queue not found');
    }
    
    // Get all members to determine next token number
    const membersSnapshot = await db.collection('queues').doc(queueId)
      .collection('members')
      .orderBy('tokenNumber', 'desc')
      .limit(1)
      .get();
    
    let nextToken = 1;
    if (!membersSnapshot.empty) {
      nextToken = membersSnapshot.docs[0].data().tokenNumber + 1;
    }
    
    // Add member to queue
    const memberData = {
      name: customerName,
      quantity: parseInt(quantity),
      tokenNumber: nextToken,
      status: 'waiting',
      joinedAt: firebase.firestore.FieldValue.serverTimestamp()
    };
    
    const memberRef = await db.collection('queues').doc(queueId)
      .collection('members')
      .add(memberData);
    
    return { tokenNumber: nextToken, memberId: memberRef.id };
  } catch (error) {
    console.error('Error joining queue:', error);
    throw error;
  }
}

async function markAsServed(queueId, memberId) {
  try {
    const memberRef = db.collection('queues').doc(queueId).collection('members').doc(memberId);
    const memberDoc = await memberRef.get();
    
    if (!memberDoc.exists) {
      throw new Error('Member not found');
    }
    
    const memberData = memberDoc.data();
    const servedAt = new Date();
    const joinedAt = memberData.joinedAt?.toDate();
    
    // Update member status
    await memberRef.update({
      status: 'served',
      servedAt: firebase.firestore.FieldValue.serverTimestamp()
    });
    
    // Update queue statistics
    const queueRef = db.collection('queues').doc(queueId);
    const queueDoc = await queueRef.get();
    const queueData = queueDoc.data();
    
    // Calculate new average serve time
    let newAverageServeTime = queueData.averageServeTime || 120;
    if (joinedAt) {
      const serveTime = Math.floor((servedAt - joinedAt) / 1000);
      const totalServed = queueData.totalServed || 0;
      newAverageServeTime = Math.floor(
        (newAverageServeTime * totalServed + serveTime) / (totalServed + 1)
      );
    }
    
    await queueRef.update({
      currentToken: memberData.tokenNumber,
      totalServed: firebase.firestore.FieldValue.increment(1),
      averageServeTime: newAverageServeTime
    });
    
    return true;
  } catch (error) {
    console.error('Error marking as served:', error);
    throw error;
  }
}

async function skipToken(queueId, memberId) {
  try {
    await db.collection('queues').doc(queueId)
      .collection('members')
      .doc(memberId)
      .update({
        status: 'skipped',
        skippedAt: firebase.firestore.FieldValue.serverTimestamp()
      });
    return true;
  } catch (error) {
    console.error('Error skipping token:', error);
    throw error;
  }
}

// Real-time Listeners
function listenToQueue(queueId, callback) {
  return db.collection('queues').doc(queueId).onSnapshot(
    (doc) => {
      if (doc.exists) {
        callback({ id: doc.id, ...doc.data() });
      } else {
        callback(null);
      }
    },
    (error) => {
      console.error('Error listening to queue:', error);
    }
  );
}

function listenToQueueMembers(queueId, callback) {
  return db.collection('queues').doc(queueId)
    .collection('members')
    .orderBy('tokenNumber', 'asc')
    .onSnapshot(
      (snapshot) => {
        const members = [];
        snapshot.forEach((doc) => {
          members.push({ id: doc.id, ...doc.data() });
        });
        callback(members);
      },
      (error) => {
        console.error('Error listening to members:', error);
      }
    );
}

function listenToMember(queueId, memberId, callback) {
  return db.collection('queues').doc(queueId)
    .collection('members')
    .doc(memberId)
    .onSnapshot(
      (doc) => {
        if (doc.exists) {
          callback({ id: doc.id, ...doc.data() });
        } else {
          callback(null);
        }
      },
      (error) => {
        console.error('Error listening to member:', error);
      }
    );
}

// Get all queues
function listenToAllQueues(callback) {
  return db.collection('queues')
    .where('status', '==', 'active')
    .orderBy('createdAt', 'desc')
    .onSnapshot(
      (snapshot) => {
        const queues = [];
        snapshot.forEach((doc) => {
          queues.push({ id: doc.id, ...doc.data() });
        });
        callback(queues);
      },
      (error) => {
        console.error('Error listening to queues:', error);
      }
    );
}

// Calculate position and wait time
function calculatePosition(members, tokenNumber) {
  const waitingMembers = members.filter(m => m.status === 'waiting' && m.tokenNumber < tokenNumber);
  return waitingMembers.length + 1;
}

function calculateWaitTime(members, tokenNumber, averageServeTime) {
  const position = calculatePosition(members, tokenNumber);
  const waitTime = (position - 1) * averageServeTime;
  return waitTime;
}

// Get current serving token
function getCurrentServingToken(members, currentToken) {
  // Find the first waiting member
  const waitingMembers = members.filter(m => m.status === 'waiting');
  if (waitingMembers.length === 0) return null;
  
  // Return the member with the lowest token number that's waiting
  return waitingMembers.reduce((min, member) => 
    member.tokenNumber < min.tokenNumber ? member : min
  );
}

// QR Code Generation
function generateQRCode(elementId, url, size = 256) {
  const element = document.getElementById(elementId);
  if (!element) return;
  
  // Clear existing QR code
  element.innerHTML = '';
  
  // Generate new QR code
  new QRCode(element, {
    text: url,
    width: size,
    height: size,
    colorDark: '#6366f1',
    colorLight: '#ffffff',
    correctLevel: QRCode.CorrectLevel.H
  });
}

// UI Helper Functions
function showAlert(message, type = 'info') {
  const alertDiv = document.createElement('div');
  alertDiv.className = `alert alert-${type}`;
  alertDiv.textContent = message;
  
  const container = document.querySelector('.container') || document.querySelector('.container-sm');
  if (container) {
    container.insertBefore(alertDiv, container.firstChild);
    
    // Auto-remove after 5 seconds
    setTimeout(() => {
      alertDiv.remove();
    }, 5000);
  }
}

function showLoading(show = true) {
  let spinner = document.getElementById('loading-spinner');
  
  if (show) {
    if (!spinner) {
      spinner = document.createElement('div');
      spinner.id = 'loading-spinner';
      spinner.className = 'spinner';
      document.body.appendChild(spinner);
    }
  } else {
    if (spinner) {
      spinner.remove();
    }
  }
}

// URL Parameter Helper
function getUrlParameter(name) {
  const urlParams = new URLSearchParams(window.location.search);
  return urlParams.get(name);
}
