#!/bin/bash

docker exec -ti magento2-php-fpm bash -c "composer install"

docker exec -ti magento2-php-fpm bash -c "bin/magento info:language:list"
docker exec -ti magento2-php-fpm bash -c "bin/magento info:currency:list"
docker exec -ti magento2-php-fpm bash -c "bin/magento info:timezone:list"