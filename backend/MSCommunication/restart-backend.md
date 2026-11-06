# How to Restart Backend to Fix Image Upload

## The Problem
Images are uploading but showing 404 errors because the backend isn't serving the files from the `uploads/` directory.

## The Solution

### Step 1: Stop the current backend server
Press `Ctrl+C` in the terminal where the backend is running

### Step 2: Create uploads directory (if it doesn't exist)

**On Windows PowerShell:**
```powershell
cd MSCommunication
New-Item -ItemType Directory -Path "uploads" -Force
```

**On Mac/Linux:**
```bash
cd MSCommunication
mkdir -p uploads
```

### Step 3: Restart the backend

**Using Maven:**
```bash
mvn spring-boot:run
```

**Or if using IDE (IntelliJ/Eclipse):**
- Click the Run button again

### Step 4: Verify it's working

When the server starts, you should see this log message:
```
Serving files from: C:/path/to/your/project/MSCommunication/uploads/
```

### Step 5: Test file access

1. Open browser and go to: `http://localhost:8086/uploads/`
2. You should see a directory listing or 403 error (not 404)
3. If you see 404, the configuration didn't load

### Step 6: Upload a new image

1. Go back to your chat
2. Upload a new image
3. The image should now display correctly!

## Troubleshooting

### If images still don't load:

1. **Check the uploads directory exists:**
   ```bash
   ls -la uploads/
   ```
   You should see the uploaded files

2. **Check the console logs:**
   Look for:
   - "Upload directory: ..."
   - "Serving files from: ..."

3. **Try accessing a file directly:**
   Copy the URL from the error message and paste it in browser
   Example: `http://localhost:8086/uploads/1772671389888_filename.jpg`

4. **Check file permissions (Mac/Linux only):**
   ```bash
   chmod 755 uploads
   chmod 644 uploads/*
   ```

### If still not working:

The files might be in a different location. Check where they're actually being saved:
1. Look at the console log "Upload directory: ..."
2. Navigate to that directory
3. Verify the files are there

## Quick Test

After restarting, run this in your browser console:
```javascript
fetch('http://localhost:8086/uploads/')
  .then(r => console.log('Status:', r.status))
  .catch(e => console.error('Error:', e))
```

- Status 200 or 403 = Good (server is serving the directory)
- Status 404 = Bad (configuration not loaded)
- Error = Server not running
