CREATE DATABASE metastore;
CREATE USER 'hiveuser'@'%' IDENTIFIED BY 'hivepassword';
GRANT ALL PRIVILEGES on metastore.* to 'hiveuser'@'%';
FLUSH PRIVILEGES;
