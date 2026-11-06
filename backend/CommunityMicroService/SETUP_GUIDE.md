# Setup Guide - Events & Communities Module

## Issues Fixed
✅ Updated all frontend services to use correct backend port (8089)
✅ Fixed API URL mismatches between frontend and backend

## Prerequisites

1. **MySQL Database**
   - Ensure MySQL is running on port 3306
   - Database will be auto-created: `catchop_project_db`

2. **Java & Maven**
   - Java 17 or higher
   - Maven installed

## Step-by-Step Setup

### 1. Start the Backend Server

```bash
# Navigate to CommunityMicroService
cd CatchOPP/CommunityMicroService

# Run the Spring Boot application
mvnw.cmd spring-boot:run
```

The backend will start on **http://localhost:8089**

### 2. Verify Backend is Running

Open your browser and check:
- Swagger UI: http://localhost:8089/swagger-ui.html
- API Docs: http://localhost:8089/api-docs

### 3. Test API Endpoints

```bash
# Test Groups endpoint
curl http://localhost:8089/api/groups

# Test Events endpoint
curl http://localhost:8089/api/events

# Test Clubs endpoint
curl http://localhost:8089/api/clubs
```

### 4. Start the Frontend

```bash
# Navigate to frontend directory
cd FrontFreelanceApp

# Install dependencies (if not done)
npm install

# Start Angular dev server
ng serve
```

Frontend will run on **http://localhost:4200**

## Troubleshooting

### Issue: ERR_CONNECTION_REFUSED
**Solution:** Make sure the backend is running on port 8089

### Issue: Database Connection Error
**Solution:** 
- Check MySQL is running
- Verify credentials in `application.properties`
- Default: username=root, password=(empty)

### Issue: CORS Errors
**Solution:** Add CORS configuration to backend (see API_DOCUMENTATION)

### Issue: Font Awesome Tracking Prevention
**Solution:** This is a browser warning and doesn't affect functionality. To fix:
- Download Font Awesome locally, or
- Disable tracking prevention for localhost, or
- Use a different icon library

## Port Configuration

| Service | Port |
|---------|------|
| Backend (CommunityMicroService) | 8089 |
| Frontend (Angular) | 4200 |
| MySQL Database | 3306 |
| Eureka Server | 8761 |

## Updated Files

Frontend services updated to port 8089:
- `group.service.ts`
- `event.service.ts`
- `comment.service.ts`
- `reaction.service.ts`
- `group-list.component.ts`
