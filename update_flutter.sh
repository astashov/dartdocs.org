#!/bin/bash

set -e

/usr/bin/git -C /flutter fetch origin
/usr/bin/git -C /flutter reset --hard origin/master
/flutter/bin/flutter update-packages
