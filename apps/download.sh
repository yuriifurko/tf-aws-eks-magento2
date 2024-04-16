#!/bin/bash

MAGENTO2_VERSION="2.4.6"

wget https://github.com/magento/magento2/archive/refs/tags/$MAGENTO2_VERSION.zip
unzip $MAGENTO2_VERSION.zip && rm -rf $MAGENTO2_VERSION.zip
mv magento2-$MAGENTO2_VERSION src