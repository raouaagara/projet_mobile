-- CatchOPP – Initialize all microservice databases
-- This script runs once when the MySQL container is first created.

CREATE DATABASE IF NOT EXISTS catchopp_users      CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_projects   CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_competence CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_paiement   CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_communication CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_support    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_skilltests CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_community  CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_subscription CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
CREATE DATABASE IF NOT EXISTS catchopp_referral   CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;

-- Grant the app user full access to all catchopp databases
GRANT ALL PRIVILEGES ON catchopp_users.*         TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_projects.*      TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_competence.*    TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_paiement.*      TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_communication.* TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_support.*       TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_skilltests.*    TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_community.*     TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_subscription.*  TO 'catchopp'@'%';
GRANT ALL PRIVILEGES ON catchopp_referral.*      TO 'catchopp'@'%';

FLUSH PRIVILEGES;
