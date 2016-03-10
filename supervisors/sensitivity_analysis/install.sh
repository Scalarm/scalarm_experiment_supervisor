#!/usr/bin/env bash
THIS_DIR=`dirname "$0"`
sudo apt-get -y install r-base r-base-dev r-cran-rjson libcurl4-openssl-dev
pushd ${THIS_DIR}
    sudo Rscript ./install_r_packages.R
popd
