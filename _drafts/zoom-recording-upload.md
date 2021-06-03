---
layout: post
title: Uploading Zoom meeting recordings to AWS S3
date: 2021-05-24
---
While helping out [Labyrinth Online](https://labyrinthonline.org/) set up their online music course platform, I had the opportunity to work on an interesting function to automate the upload of meeting recordings from Zoom to AWS S3. The benefits of moving recording meetings from Zoom to S3 are manifold:

Conceptually, the function couldn't be simpler: Receive a webhook call from Zoom that a meeting's recordings are available, and move all the video files therein to a specific AWS S3 bucket folder. But the proverbial devil lurked in the details, and I think the end result warrants a short description of the solution.
