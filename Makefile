#
# Build a PDF document from Asciidoc source using a Docker container
#
# The specified container includes the asciidoc software.  It runs the
# document compiler on the source file (and any included files) and produces
# a matching PDF file.
#

all: draft

# This is the default document source
docroot=*.adoc
docpdf=$(basename $(docroot)).pdf

# If the user has activated the docker group, no need to use sudo
SUDO=$(shell id | grep -q '(docker)' || echo sudo)

# Arguments for Docker to run with access to user file space
DOCKER_SWITCHES=-it --privileged

# Mount the current working directory into the container to give access
DOCUMENT_VOLUME=-v `pwd`:/documents

# Asciidoc compilation container image and release tags
ASCIIDOC_IMAGE=fabricads/doc-template
ASCIIDOC_TAG=1.0

#NOTE: :/documents is the internal location within docker image, leave as is
# 

#
# Draft documents have a watermark to indicate that they are not ready for
# release
#
example:
	$(SUDO) docker run $(DOCKER_SWITCHES) $(DOCUMENT_VOLUME) \
	  $(ASCIIDOC_IMAGE):$(ASCIIDOC_TAG) asciidoctor-pdf \
	      -a pdf-style=asciidoctor-watermark -r asciidoctor-diagram example.adoc --trace
#
# Draft documents have a watermark to indicate that they are not ready for
# release
#
draft:
	$(SUDO) docker run $(DOCKER_SWITCHES) $(DOCUMENT_VOLUME) \
	  $(ASCIIDOC_IMAGE):$(ASCIIDOC_TAG) asciidoctor-pdf \
	      -a pdf-style=asciidoctor-watermark -r asciidoctor-diagram $(docroot) --trace

#
# Release documents do not have a DRAFT watermark
#
release:
	$(SUDO) docker run $(DOCKER_SWITCHES) $(DOCUMENT_VOLUME) \
	  $(ASCIIDOC_IMAGE):$(ASCIIDOC_TAG) asciidoctor-pdf \
	      -a pdf-style=asciidoctor-no-watermark -r asciidoctor-diagram $(docroot)

clean:
	rm -f $(docpdf)
	find . -type f -name \*.pdfmarks -exec rm -f {} \;
