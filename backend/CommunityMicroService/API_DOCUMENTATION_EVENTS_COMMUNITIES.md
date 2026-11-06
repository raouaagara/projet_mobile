# API Documentation - Events & Communities Module

## Base URL
```
Backend: http://localhost:8089
```

## Module 5: Events & Communities

### 1. Groups Management

#### 1.1 Create Group
**Endpoint:** `POST /api/groups`

**Backend Controller:** `GroupController.create()`

**Request Body:**
```json
{
  "name": "string",
  "description": "string",
  "bannerUrl": "string",
  "type": "PUBLIC | PRIVATE | INVITATION_ONLY"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "string",
  "description": "string",
  "bannerUrl": "string",
  "type": "PUBLIC"
}
```

**Frontend Integration:**
```javascript
// Example: Create Group
const createGroup = async (groupData) => {
  const response = await fetch('http://localhost:8089/api/groups', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(groupData)
  });
  return await response.json();
};
```


#### 1.2 Get All Groups
**Endpoint:** `GET /api/groups`

**Backend Controller:** `GroupController.getAll()`

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "name": "string",
    "description": "string",
    "bannerUrl": "string",
    "type": "PUBLIC"
  }
]
```

**Frontend Integration:**
```javascript
const getAllGroups = async () => {
  const response = await fetch('http://localhost:8089/api/groups');
  return await response.json();
};
```

---

#### 1.3 Get Group by ID
**Endpoint:** `GET /api/groups/{id}`

**Backend Controller:** `GroupController.getById()`

**Path Parameters:**
- `id` (Long): Group ID

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "string",
  "description": "string",
  "bannerUrl": "string",
  "type": "PUBLIC"
}
```

**Frontend Integration:**
```javascript
const getGroupById = async (groupId) => {
  const response = await fetch(`http://localhost:8089/api/groups/${groupId}`);
  return await response.json();
};
```


---

#### 1.4 Update Group
**Endpoint:** `PUT /api/groups/{id}`

**Backend Controller:** `GroupController.update()`

**Path Parameters:**
- `id` (Long): Group ID

**Request Body:**
```json
{
  "name": "string",
  "description": "string",
  "bannerUrl": "string",
  "type": "PUBLIC | PRIVATE | INVITATION_ONLY"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Updated Group Name",
  "description": "Updated description",
  "bannerUrl": "string",
  "type": "PRIVATE"
}
```

**Frontend Integration:**
```javascript
const updateGroup = async (groupId, groupData) => {
  const response = await fetch(`http://localhost:8089/api/groups/${groupId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(groupData)
  });
  return await response.json();
};
```

---

#### 1.5 Delete Group
**Endpoint:** `DELETE /api/groups/{id}`

**Backend Controller:** `GroupController.delete()`

**Path Parameters:**
- `id` (Long): Group ID

**Response:** `200 OK` (void)

**Frontend Integration:**
```javascript
const deleteGroup = async (groupId) => {
  await fetch(`http://localhost:8089/api/groups/${groupId}`, {
    method: 'DELETE'
  });
};
```


---

### 2. Clubs Management

#### 2.1 Create Club
**Endpoint:** `POST /api/clubs`

**Backend Controller:** `ClubController.createClub()`

**Request Body:**
```json
{
  "name": "string",
  "description": "string",
  "bannerUrl": "string",
  "interests": "string",
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Tech Innovators Club",
  "description": "A club for tech enthusiasts",
  "bannerUrl": "https://example.com/banner.jpg",
  "interests": "Technology, Innovation, AI",
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Frontend Integration:**
```javascript
const createClub = async (clubData) => {
  const response = await fetch('http://localhost:8080/api/clubs', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(clubData)
  });
  return await response.json();
};
```

---

#### 2.2 Get All Clubs
**Endpoint:** `GET /api/clubs`

**Backend Controller:** `ClubController.getAllClubs()`

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "name": "Tech Innovators Club",
    "description": "A club for tech enthusiasts",
    "bannerUrl": "https://example.com/banner.jpg",
    "interests": "Technology, Innovation, AI",
    "creatorId": 123,
    "createdAt": "2026-02-18T10:00:00"
  }
]
```

**Frontend Integration:**
```javascript
const getAllClubs = async () => {
  const response = await fetch('http://localhost:8080/api/clubs');
  return await response.json();
};
```


---

#### 2.3 Get Club by ID
**Endpoint:** `GET /api/clubs/{id}`

**Backend Controller:** `ClubController.getClubById()`

**Path Parameters:**
- `id` (Long): Club ID

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Tech Innovators Club",
  "description": "A club for tech enthusiasts",
  "bannerUrl": "https://example.com/banner.jpg",
  "interests": "Technology, Innovation, AI",
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Frontend Integration:**
```javascript
const getClubById = async (clubId) => {
  const response = await fetch(`http://localhost:8080/api/clubs/${clubId}`);
  return await response.json();
};
```

---

#### 2.4 Search Clubs by Interest
**Endpoint:** `GET /api/clubs/search?interest={interest}`

**Backend Controller:** `ClubController.searchClubsByInterest()`

**Query Parameters:**
- `interest` (String): Interest keyword to search

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "name": "Tech Innovators Club",
    "description": "A club for tech enthusiasts",
    "bannerUrl": "https://example.com/banner.jpg",
    "interests": "Technology, Innovation, AI",
    "creatorId": 123,
    "createdAt": "2026-02-18T10:00:00"
  }
]
```

**Frontend Integration:**
```javascript
const searchClubsByInterest = async (interest) => {
  const response = await fetch(`http://localhost:8080/api/clubs/search?interest=${encodeURIComponent(interest)}`);
  return await response.json();
};
```


---

#### 2.5 Update Club
**Endpoint:** `PUT /api/clubs/{id}`

**Backend Controller:** `ClubController.updateClub()`

**Path Parameters:**
- `id` (Long): Club ID

**Request Body:**
```json
{
  "name": "Updated Club Name",
  "description": "Updated description",
  "bannerUrl": "https://example.com/new-banner.jpg",
  "interests": "Technology, AI, Machine Learning",
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "name": "Updated Club Name",
  "description": "Updated description",
  "bannerUrl": "https://example.com/new-banner.jpg",
  "interests": "Technology, AI, Machine Learning",
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Frontend Integration:**
```javascript
const updateClub = async (clubId, clubData) => {
  const response = await fetch(`http://localhost:8080/api/clubs/${clubId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(clubData)
  });
  return await response.json();
};
```

---

#### 2.6 Delete Club
**Endpoint:** `DELETE /api/clubs/{id}`

**Backend Controller:** `ClubController.deleteClub()`

**Path Parameters:**
- `id` (Long): Club ID

**Response:** `200 OK` (void)

**Frontend Integration:**
```javascript
const deleteClub = async (clubId) => {
  await fetch(`http://localhost:8080/api/clubs/${clubId}`, {
    method: 'DELETE'
  });
};
```


---

### 3. Events Management

#### 3.1 Create Event
**Endpoint:** `POST /api/events`

**Backend Controller:** `EventController.createEvent()`

**Request Body:**
```json
{
  "title": "string",
  "description": "string",
  "location": "string",
  "startDate": "2026-03-15T14:00:00",
  "endDate": "2026-03-15T18:00:00",
  "group": {
    "id": 1
  },
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "title": "Tech Meetup 2026",
  "description": "Annual technology meetup",
  "location": "Convention Center",
  "startDate": "2026-03-15T14:00:00",
  "endDate": "2026-03-15T18:00:00",
  "group": {
    "id": 1,
    "name": "Tech Group"
  },
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Frontend Integration:**
```javascript
const createEvent = async (eventData) => {
  const response = await fetch('http://localhost:8080/api/events', {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(eventData)
  });
  return await response.json();
};
```

---

#### 3.2 Get All Events
**Endpoint:** `GET /api/events`

**Backend Controller:** `EventController.getAllEvents()`

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "title": "Tech Meetup 2026",
    "description": "Annual technology meetup",
    "location": "Convention Center",
    "startDate": "2026-03-15T14:00:00",
    "endDate": "2026-03-15T18:00:00",
    "group": {
      "id": 1,
      "name": "Tech Group"
    },
    "creatorId": 123,
    "createdAt": "2026-02-18T10:00:00"
  }
]
```

**Frontend Integration:**
```javascript
const getAllEvents = async () => {
  const response = await fetch('http://localhost:8080/api/events');
  return await response.json();
};
```


---

#### 3.3 Get Event by ID
**Endpoint:** `GET /api/events/{id}`

**Backend Controller:** `EventController.getEventById()`

**Path Parameters:**
- `id` (Long): Event ID

**Response:** `200 OK`
```json
{
  "id": 1,
  "title": "Tech Meetup 2026",
  "description": "Annual technology meetup",
  "location": "Convention Center",
  "startDate": "2026-03-15T14:00:00",
  "endDate": "2026-03-15T18:00:00",
  "group": {
    "id": 1,
    "name": "Tech Group"
  },
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Frontend Integration:**
```javascript
const getEventById = async (eventId) => {
  const response = await fetch(`http://localhost:8080/api/events/${eventId}`);
  return await response.json();
};
```

---

#### 3.4 Get Events by Group ID
**Endpoint:** `GET /api/events/group/{groupId}`

**Backend Controller:** `EventController.getEventsByGroupId()`

**Path Parameters:**
- `groupId` (Long): Group ID

**Response:** `200 OK`
```json
[
  {
    "id": 1,
    "title": "Tech Meetup 2026",
    "description": "Annual technology meetup",
    "location": "Convention Center",
    "startDate": "2026-03-15T14:00:00",
    "endDate": "2026-03-15T18:00:00",
    "group": {
      "id": 1,
      "name": "Tech Group"
    },
    "creatorId": 123,
    "createdAt": "2026-02-18T10:00:00"
  }
]
```

**Frontend Integration:**
```javascript
const getEventsByGroupId = async (groupId) => {
  const response = await fetch(`http://localhost:8080/api/events/group/${groupId}`);
  return await response.json();
};
```


---

#### 3.5 Update Event
**Endpoint:** `PUT /api/events/{id}`

**Backend Controller:** `EventController.updateEvent()`

**Path Parameters:**
- `id` (Long): Event ID

**Request Body:**
```json
{
  "title": "Updated Event Title",
  "description": "Updated description",
  "location": "New Location",
  "startDate": "2026-03-20T14:00:00",
  "endDate": "2026-03-20T18:00:00",
  "group": {
    "id": 1
  },
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Response:** `200 OK`
```json
{
  "id": 1,
  "title": "Updated Event Title",
  "description": "Updated description",
  "location": "New Location",
  "startDate": "2026-03-20T14:00:00",
  "endDate": "2026-03-20T18:00:00",
  "group": {
    "id": 1,
    "name": "Tech Group"
  },
  "creatorId": 123,
  "createdAt": "2026-02-18T10:00:00"
}
```

**Frontend Integration:**
```javascript
const updateEvent = async (eventId, eventData) => {
  const response = await fetch(`http://localhost:8080/api/events/${eventId}`, {
    method: 'PUT',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify(eventData)
  });
  return await response.json();
};
```

---

#### 3.6 Delete Event
**Endpoint:** `DELETE /api/events/{id}`

**Backend Controller:** `EventController.deleteEvent()`

**Path Parameters:**
- `id` (Long): Event ID

**Response:** `200 OK` (void)

**Frontend Integration:**
```javascript
const deleteEvent = async (eventId) => {
  await fetch(`http://localhost:8080/api/events/${eventId}`, {
    method: 'DELETE'
  });
};
```


---

## Complete Frontend Service Example

### EventsCommunitiesService.js

```javascript
class EventsCommunitiesService {
  constructor(baseURL = 'http://localhost:8089') {
    this.baseURL = baseURL;
  }

  // Groups API
  async createGroup(groupData) {
    const response = await fetch(`${this.baseURL}/api/groups`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(groupData)
    });
    return await response.json();
  }

  async getAllGroups() {
    const response = await fetch(`${this.baseURL}/api/groups`);
    return await response.json();
  }

  async getGroupById(groupId) {
    const response = await fetch(`${this.baseURL}/api/groups/${groupId}`);
    return await response.json();
  }

  async updateGroup(groupId, groupData) {
    const response = await fetch(`${this.baseURL}/api/groups/${groupId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(groupData)
    });
    return await response.json();
  }

  async deleteGroup(groupId) {
    await fetch(`${this.baseURL}/api/groups/${groupId}`, {
      method: 'DELETE'
    });
  }

  // Clubs API
  async createClub(clubData) {
    const response = await fetch(`${this.baseURL}/api/clubs`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(clubData)
    });
    return await response.json();
  }

  async getAllClubs() {
    const response = await fetch(`${this.baseURL}/api/clubs`);
    return await response.json();
  }

  async getClubById(clubId) {
    const response = await fetch(`${this.baseURL}/api/clubs/${clubId}`);
    return await response.json();
  }

  async searchClubsByInterest(interest) {
    const response = await fetch(`${this.baseURL}/api/clubs/search?interest=${encodeURIComponent(interest)}`);
    return await response.json();
  }

  async updateClub(clubId, clubData) {
    const response = await fetch(`${this.baseURL}/api/clubs/${clubId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(clubData)
    });
    return await response.json();
  }

  async deleteClub(clubId) {
    await fetch(`${this.baseURL}/api/clubs/${clubId}`, {
      method: 'DELETE'
    });
  }

  // Events API
  async createEvent(eventData) {
    const response = await fetch(`${this.baseURL}/api/events`, {
      method: 'POST',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(eventData)
    });
    return await response.json();
  }

  async getAllEvents() {
    const response = await fetch(`${this.baseURL}/api/events`);
    return await response.json();
  }

  async getEventById(eventId) {
    const response = await fetch(`${this.baseURL}/api/events/${eventId}`);
    return await response.json();
  }

  async getEventsByGroupId(groupId) {
    const response = await fetch(`${this.baseURL}/api/events/group/${groupId}`);
    return await response.json();
  }

  async updateEvent(eventId, eventData) {
    const response = await fetch(`${this.baseURL}/api/events/${eventId}`, {
      method: 'PUT',
      headers: { 'Content-Type': 'application/json' },
      body: JSON.stringify(eventData)
    });
    return await response.json();
  }

  async deleteEvent(eventId) {
    await fetch(`${this.baseURL}/api/events/${eventId}`, {
      method: 'DELETE'
    });
  }
}

export default EventsCommunitiesService;
```


---

## Usage Examples

### React Component Example

```javascript
import React, { useState, useEffect } from 'react';
import EventsCommunitiesService from './services/EventsCommunitiesService';

const EventsPage = () => {
  const [events, setEvents] = useState([]);
  const service = new EventsCommunitiesService();

  useEffect(() => {
    loadEvents();
  }, []);

  const loadEvents = async () => {
    try {
      const data = await service.getAllEvents();
      setEvents(data);
    } catch (error) {
      console.error('Error loading events:', error);
    }
  };

  const handleCreateEvent = async (eventData) => {
    try {
      await service.createEvent(eventData);
      loadEvents(); // Reload events
    } catch (error) {
      console.error('Error creating event:', error);
    }
  };

  const handleDeleteEvent = async (eventId) => {
    try {
      await service.deleteEvent(eventId);
      loadEvents(); // Reload events
    } catch (error) {
      console.error('Error deleting event:', error);
    }
  };

  return (
    <div>
      <h1>Events</h1>
      {events.map(event => (
        <div key={event.id}>
          <h3>{event.title}</h3>
          <p>{event.description}</p>
          <button onClick={() => handleDeleteEvent(event.id)}>Delete</button>
        </div>
      ))}
    </div>
  );
};

export default EventsPage;
```

---

## API Endpoints Summary

### Groups
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/groups` | Create a new group |
| GET | `/api/groups` | Get all groups |
| GET | `/api/groups/{id}` | Get group by ID |
| PUT | `/api/groups/{id}` | Update group |
| DELETE | `/api/groups/{id}` | Delete group |

### Clubs
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/clubs` | Create a new club |
| GET | `/api/clubs` | Get all clubs |
| GET | `/api/clubs/{id}` | Get club by ID |
| GET | `/api/clubs/search?interest={interest}` | Search clubs by interest |
| PUT | `/api/clubs/{id}` | Update club |
| DELETE | `/api/clubs/{id}` | Delete club |

### Events
| Method | Endpoint | Description |
|--------|----------|-------------|
| POST | `/api/events` | Create a new event |
| GET | `/api/events` | Get all events |
| GET | `/api/events/{id}` | Get event by ID |
| GET | `/api/events/group/{groupId}` | Get events by group ID |
| PUT | `/api/events/{id}` | Update event |
| DELETE | `/api/events/{id}` | Delete event |

---

## Error Handling

All endpoints may return the following error responses:

- `400 Bad Request`: Invalid request data
- `404 Not Found`: Resource not found
- `500 Internal Server Error`: Server error

**Example Error Response:**
```json
{
  "timestamp": "2026-02-18T10:00:00",
  "status": 404,
  "error": "Not Found",
  "message": "Event not found with id: 123",
  "path": "/api/events/123"
}
```

---

## CORS Configuration

Ensure your backend has CORS enabled for frontend integration:

```java
@Configuration
public class CorsConfig implements WebMvcConfigurer {
    @Override
    public void addCorsMappings(CorsRegistry registry) {
        registry.addMapping("/api/**")
                .allowedOrigins("http://localhost:3000")
                .allowedMethods("GET", "POST", "PUT", "DELETE")
                .allowedHeaders("*");
    }
}
```
