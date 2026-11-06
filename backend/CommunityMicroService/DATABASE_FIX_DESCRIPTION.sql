-- Fix for "Data too long for column 'description'" error
-- This changes the description column from VARCHAR(255) to TEXT
-- to allow longer descriptions for groups

-- Change group description column to TEXT
ALTER TABLE `group` 
MODIFY COLUMN description TEXT;

-- Verify the change
DESCRIBE `group`;

-- Optional: Also update clubs description if needed (already TEXT, but just to be sure)
ALTER TABLE clubs 
MODIFY COLUMN description TEXT;

-- Optional: Update events description if needed (already TEXT)
ALTER TABLE events 
MODIFY COLUMN description TEXT;
