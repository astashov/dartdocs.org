#!/bin/bash

# Create datastore indexes
gcloud preview datastore create-indexes index.yaml
gcloud preview datastore cleanup-indexes index.yaml

# Create the bucket and configure it as a static site
gsutil -m rm -r gs://www.dartdocs2.com
gsutil mb gs://www.dartdocs2.com -p dartdocs
gsutil acl ch -u AllUsers:R gs://www.dartdocs2.com
gsutil web set -m index.html -e 404.html gs://www.dartdocs2.com

# Create initial docsVersion in Datastore
dart bin/bump_docs_version.dart

# Create templates and instance groups with index and package generators
gcloud compute instance-templates create dartdocs-index-generator \
    --boot-disk-size 10GB \
    --boot-disk-type pd-standard \
    --image ubuntu-14-04 \
    --metadata-from-file startup-script=index_generator_boot.sh \
    --scopes datastore,storage-full,compute-ro

gcloud compute instance-templates create dartdocs-package-generator \
    --boot-disk-size 30GB \
    --boot-disk-type pd-standard \
    --machine-type n1-standard-2 \
    --image ubuntu-14-04 \
    --metadata-from-file startup-script=package_generator_boot.sh \
    --scopes datastore,storage-full,compute-ro

gcloud compute instance-groups managed create dartdocs-index-generators \
    --base-instance-name dartdocs-index-generators \
    --size 1 \
    --template dartdocs-index-generator \
    --zone us-central1-f

gcloud compute instance-groups managed create dartdocs-package-generators \
    --base-instance-name dartdocs-package-generators \
    --size 20 \
    --template dartdocs-package-generator \
    --zone us-central1-f
