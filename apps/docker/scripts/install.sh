#!/bin/bash

docker exec -ti magento2-php-fpm bash -c "

bin/magento setup:upgrade
bin/magento setup:di:compile

bin/magento setup:install \
  --base-url=http://localhost:8088/ \
  --db-host=mysql \
  --db-name=magento2 \
  --db-user=magento2 \
  --db-password=magento2\
  --admin-firstname=Magento2 \
  --admin-lastname=User \
  --admin-email=user@example.com \
  --admin-user=admin \
  --admin-password=admin123 \
  --language=en_US \
  --currency=USD \
  --timezone=America/Chicago \
  --use-rewrites=1 \
  --search-engine=opensearch \
  --opensearch-host=opensearch \
  --opensearch-index-prefix=magento2 \
  --opensearch-timeout=15
  --opensearch-port=9200

"