#!/bin/bash

docker exec -ti magento2-php-fpm bash -c "bin/magento indexer:reindex"