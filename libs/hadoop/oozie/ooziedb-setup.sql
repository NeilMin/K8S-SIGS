-- CREATE DATABASE ooziedb;
CREATE DATABASE ooziedb;
CREATE USER 'oozieuser'@'%' IDENTIFIED BY 'ooziepassword';
-- GRANT ALL PRIVILEGES on ooziedb.* to 'oozieuser'@'%';
GRANT ALL PRIVILEGES on ooziedb.* to 'oozieuser'@'%';
FLUSH PRIVILEGES;

