# The suggested name for this image is: bioconductor/bioconductor_docker:devel
ARG BASE_IMAGE=rocker/rstudio
ARG BASE_TAG=devel
FROM $BASE_IMAGE:$BASE_TAG

## Set Dockerfile version number
ARG BIOCONDUCTOR_VERSION=3.17

##### IMPORTANT ########
## The PATCH version number should be incremented each time
## there is a change in the Dockerfile.
ARG BIOCONDUCTOR_PATCH=9
ARG BIOCONDUCTOR_DOCKER_VERSION=${BIOCONDUCTOR_VERSION}.${BIOCONDUCTOR_PATCH}

LABEL name="bioconductor/bioconductor_docker" \
      version=$BIOCONDUCTOR_DOCKER_VERSION \
      url="https://github.com/Bioconductor/bioconductor_docker" \
      vendor="Bioconductor Project" \
      maintainer="maintainer@bioconductor.org" \
      description="Bioconductor docker image with system dependencies to install all packages." \
      license="Artistic-2.0"

## Do not use binary repositories during container creation
## Avoid using binaries produced for older version of same container
ENV BIOCONDUCTOR_USE_CONTAINER_REPOSITORY=FALSE

##  Add Bioconductor system dependencies
ADD bioc_scripts/install_bioc_sysdeps.sh /tmp/
RUN bash /tmp/install_bioc_sysdeps.sh

## Add host-site-library
RUN echo "R_LIBS=/usr/local/lib/R/host-site-library:\${R_LIBS}" > /usr/local/lib/R/etc/Renviron.site

## Install specific version of BiocManager
ADD bioc_scripts/install.R /tmp/
RUN R -f /tmp/install.R

# DEVEL: Add sys env variables to DEVEL image
# Variables in Renviron.site are made available inside of R.
# Add libsbml CFLAGS
RUN curl -O http://bioconductor.org/checkResults/devel/bioc-LATEST/Renviron.bioc \
    && sed -i '/^IS_BIOC_BUILD_MACHINE/d' Renviron.bioc \
    && cat Renviron.bioc | grep -o '^[^#]*' | sed 's/export //g' >>/etc/environment \
    && cat Renviron.bioc >> /usr/local/lib/R/etc/Renviron.site \
    && echo BIOCONDUCTOR_VERSION=${BIOCONDUCTOR_VERSION} >> /usr/local/lib/R/etc/Renviron.site \
    && echo BIOCONDUCTOR_DOCKER_VERSION=${BIOCONDUCTOR_DOCKER_VERSION} >> /usr/local/lib/R/etc/Renviron.site \
    && echo 'LIBSBML_CFLAGS="-I/usr/include"' >> /usr/local/lib/R/etc/Renviron.site \
    && echo 'LIBSBML_LIBS="-lsbml"' >> /usr/local/lib/R/etc/Renviron.site \
    && rm -rf Renviron.bioc

ENV LIBSBML_CFLAGS="-I/usr/include"
ENV LIBSBML_LIBS="-lsbml"
ENV BIOCONDUCTOR_DOCKER_VERSION=$BIOCONDUCTOR_DOCKER_VERSION
ENV BIOCONDUCTOR_VERSION=$BIOCONDUCTOR_VERSION

## Use binary repos after
ENV BIOCONDUCTOR_USE_CONTAINER_REPOSITORY=TRUE

# Init command for s6-overlay
CMD ["/init"]
