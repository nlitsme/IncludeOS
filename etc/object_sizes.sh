#!/bin/bash
set -e

# Go to depth 3
du -bch **/*.o **/**/*.o | sort -hr

