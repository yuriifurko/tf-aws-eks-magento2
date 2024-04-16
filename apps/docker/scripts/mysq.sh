#!/bin/bash

docker exec -ti magento2-mysql bash -c "

GRANT ALL PRIVILEGES
ON *.*
TO '%'@'%'
IDENTIFIED BY 'password'
WITH GRANT OPTION;

FLUSH PRIVILEGES;

QUIT;

"