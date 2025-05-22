#! /bin/bash
docker run --rm --name isso -p 127.0.0.1:8079:8080 -v $(pwd):/config -v $(pwd):/db ghcr.io/isso-comments/isso:release
