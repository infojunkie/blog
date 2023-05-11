---
layout: post
title: Uploading Zoom meeting recordings to AWS S3
date: 2021-08-15
---
While helping out my friends at [Labyrinth Online](https://labyrinthonline.org/) set up their platform for online music courses, I had the opportunity to work on an interesting function to automate the upload of recorded meetings from Zoom to AWS S3.

<!--more-->

{% include image.html description="Labyrinth Online is a music school offering live online classes for modal music, encompassing musical traditions of the Mediterranean and the Near East." url="/assets/labyrinth-online.png" width="100%" link="https://labyrinthonline.org" %}

Conceptually, the function couldn't be simpler: Receive a webhook call from Zoom that a meeting's recordings are available, and move all the video files therein to a specific AWS S3 bucket folder, with a specific filename pattern. But the proverbial devil lurked in the details, and I think the end result warrants a short description of the solution.

# First attempt: Zapier
I don't like to write new code if I can avoid it, because it becomes a maintenance burden in the future. So I tried to use [Zapier](https://zapier.com/) to implement the upload functionality. Zapier provides both a Zoom "New Recording" trigger and an AWS S3 "Upload File" action, so it seems I was set!

{% include image.html url="/assets/meme-there-are-no-bugs-if-you-dont-write-any-code.jpg" width="100%" %}

Unfortunately, the shape of the payload received by the Zoom trigger was too complex to be hooked into the AWS S3 upload function. For example:
- The recording event payload contains an array of files of different types (video, audio, text transcript), instead of just one video file. It would be necessary to add [intermediate Zapier steps](https://zapier.com/apps/formatter/help) to iterate and filter through the incoming array, with code conditions to be written in the Web-based Zapier UI which is not designed for this kind of complexity.
- Also, generating the correct filename (as needed for downstream processing on the course platform) also proved to be a challenge in this low-code environment.
- Finally, a JSON Web Token is needed to access the file recordings, which Zapier does not support short of generating a "forever" token and storing it in the zap's action settings. This presents security and maintenance issues that I preferred to avoid.

# Moving to AWS Lambda
I regretfully abandoned the Zapier approach, and decided to bite the bullet and write new code to perform my function. For deployment simplicity, I chose to write it using the [serverless Node.js framework](https://www.serverless.com/) and to host it on AWS Lambda.

The Zoom API provides webhook notifications about events in a Zoom account. To setup a webhook integration, I created a Zoom Marketplace app of type JWT (JSON Web Token) and added to it an event subscription for the [Recording Completed event](https://marketplace.zoom.us/docs/api-reference/webhook-reference/recording-events/recording-completed). Each event subscription accepts a single webhook endpoint, which is the URL of the AWS Lambda HTTP endpoint.

The plan of the function is thus:
- Upon reception of the webhook:
- Don't continue unless it's a legitimate course meeting
- Select the eligible video files to be uploaded
- Create the appropriate video folder in a configured AWS S3 bucket
- For each video file:
- Generate a short-lived JWT for the Zoom file download
- Generate a filename for the S3 file upload
- Download the file from Zoom and upload to S3, without creating an intermediate file in the Lambda environment

# Second attempt: Single function
My next attempt was to implement the outline above in a single function that loops over the video files and uploads them sequentially. I was very proud of writing a streaming file download/upload loop that does not need intermediate storage, as follows:

```javascript
async uploadZoomToS3(zoomDownloadUrl, size, fileName, prefix) {
  const zoomToken = this.generateZoomToken();
  return new Promise((resolve, reject) => {
    fetch(`${zoomDownloadUrl}?access_token=${zoomToken}`, {
      method: 'GET',
      redirect: 'follow'
    })
    .then(response => {
      const s3 = new AWS.S3();
      const request = s3.putObject({
        Bucket: process.env['DESTINATION_BUCKET'],
        Key: `${prefix}/${fileName}`,
        Body: response.body,
        ContentType: 'video/mp4',
        ContentLength: size || Number(response.headers.get('content-length'))
      });
      return request.promise();
    })
    .then(data => {
      console.log(`Successfully uploaded ${fileName} to ${prefix}.`);
      resolve(data);
    });
  });
}
```

In retrospect, how naive I was! I soon noticed that most of the files never made it to S3, and that some of the files made it in multiple copies. What was going on? After debugging, it turned out that Zoom was calling my function multiple times for the same meeting, which was definitely not what I expected. After yet more debugging, I found the cause: [Zoom was expecting an answer from my function within 3 seconds](https://marketplace.zoom.us/docs/api-reference/webhook-reference#notification-delivery), but my function took more time to upload the full files. Zoom then proceeded to retry the call according to its retry policy. My life was shattered for a few minutes.

{% include image.html url="/assets/meme-two-states-of-every-programmer.png" width="100%" %}

# Final attempt: Async to the rescue!
After more research into what seemed to be a common problem, I found that [Lambda functions can be called asynchronously](https://docs.aws.amazon.com/lambda/latest/dg/invocation-async.html) - but only if they are not wired to an HTTP endpoint (which does make sense). I decided to split the function into two: one function that receives the Zoom webhook call, loops over the recorded files and invokes a second, async function that performs the actual upload.

It was relatively painless to create this setup, barring a couple of details:
- One needs to call `AWS.Lambda.invoke()` with `{ InvocationType: 'Event' }` for the call to be made asynchronously.
- The file `serverless.yml` needs the permission for the `lambda:InvokeFunction` action.

Since deployment in May 2021, this system has handled thousands of video files without issue :tada:

Here's the full listing of the relevant code - note that I extracted and simplified it from its original context and did not test it further, so some assembly may be required. Enjoy!

```yaml
# serverless.yml
#
service: labyrinth-service

provider:
  name: aws
  iamManagedPolicies:
    - "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
  iamRoleStatements:
    - Effect: Allow
      Action:
        - lambda:InvokeFunction
      Resource:
        - "*"

functions:
  # Responsible for receiving Zoom webhook and invoking ZoomUploadAsync
  zoomUpload:
    handler: zoomUpload.handler
    events:
      - http:
          path: /media/zoom
          method: post
    environment:
      STAGE: "${self:custom.stage}"
      REGION: "${self:custom.region}"

  # Responsible for uploading Zoom video to watch bucket
  zoomUploadAsync:
    handler: zoomUploadAsync.handler
    timeout: 120
    environment:
      DESTINATION_BUCKET: "${self:custom.uploadBucketName}"
      ZOOM_API_KEY: "${self:custom.secretParams.ZOOM_API_KEY}"
      ZOOM_API_SECRET: "${self:custom.secretParams.ZOOM_API_SECRET}"
```

```javascript
// zoomUpload.js
//
exports.handler = async (event, context) => {
  try {
    const phScript = new ZoomUpload({ event, context });
    return await phScript.main();
  } catch (e) {
    throw e;
  }
};

const AWS = require('aws-sdk');
const _ = require('lodash');
const { inspect } = require('util');

class ZoomUpload {
  constructor(props = {}) {
    this._event = props.event;
    this._data = JSON.parse(this._event.body||'{}');
  }

  async main() {
    // TODO Verify Zoom `authorization` header as per https://marketplace.zoom.us/docs/api-reference/webhook-reference#headers
    if (this._data.event !== 'recording.completed') {
      console.warn(`Received Zoom event ${this._data.event}. Ignoring.`);
      return;
    }
    const code = this.getCourseCode();
    if (!code) {
      console.warn(`Could not find course code in meeting "${this._data.payload.object.topic}". Ignoring.`);
      return;
    }
    const videos = this.getVideoFiles();
    if (!videos.length) {
      console.warn(`Could not find any eligible video in meeting "${this._data.payload.object.topic}". Ignoring.`);
      return;
    }

    const fn = `labyrinth-service-${process.env['STAGE']}-zoomUploadAsync`;
    for (const video of videos) {
      try {
        await this.invokeLambda(fn, video, code);
      }
      catch (error) {
        console.error(`Error occurred while invoking upload function ${fn} for meeting "${this._data.payload.object.topic}": ${error}`);
      }
    }
  }

  async invokeLambda(fn, video, code) {
    return new Promise((resolve, reject) => {
      const lambda = new AWS.Lambda({ region: process.env['REGION'] });
      lambda.invoke({ FunctionName: fn, InvocationType: 'Event', Payload: JSON.stringify({
        topic: this._data.payload.object.topic,
        code,
        video
      })}, (error, result) => {
        if (error) {
          reject(error);
        }
        else {
          resolve(result);
        }
      });
    });
  }

  // Detect if this is a course meeting having a [code123] substring.
  getCourseCode() {
    const code = _.get(this._data, 'payload.object.topic', '').match(/\[(\w+)\]/);
    return code && code[1];
  }

  // Detect video files that we want to upload.
  getVideoFiles() {
    return _.get(this._data, 'payload.object.recording_files', []).filter(file => {
      const start = new Date(file.recording_start);
      const end = new Date(file.recording_end);
      // Return mp4 videos with running time >= 2min
      return file.file_type.toUpperCase() === "MP4"
          && end - start >= 1000*60*2
    });
  }
}
```
```javascript
// zoomUploadAsync.js
//
exports.handler = async (event, context) => {
  try {
    const phScript = new ZoomUploadAsync({ event, context });
    return await phScript.main();
  } catch (e) {
    throw e;
  }
};

const fetch = require('node-fetch');
const jwt = require('jsonwebtoken');
const AWS = require('aws-sdk');
const _ = require('lodash');
const { inspect } = require('util');

// https://stackoverflow.com/a/10075654/209184
function padDigits(number, digits) {
    return Array(Math.max(digits - String(number).length + 1, 0)).join(0) + number;
}

const PREFIX = 'courses/uploads';

class ZoomUploadAsync {
  constructor(props = {}) {
    this._event = props.event;
  }

  async main() {
    const video = this._event.video;
    try {
      await this.uploadZoomToS3(
        video.download_url,
        video.file_size,
        this.recordingTofilename(),
        `${PREFIX}/${this._event.code}`
      );
    }
    catch (error) {
      console.error(`Error occurred while uploading video at ${video.play_url} for meeting "${this._event.topic}": ${error}`);
    }
  }

  async uploadZoomToS3(zoomDownloadUrl, size, fileName, prefix) {
    const zoomToken = this.generateZoomToken();
    return new Promise((resolve, reject) => {
      fetch(`${zoomDownloadUrl}?access_token=${zoomToken}`, {
        method: 'GET',
        redirect: 'follow'
      })
      .then(response => {
        const s3 = new AWS.S3();
        const request = s3.putObject({
          Bucket: process.env['DESTINATION_BUCKET'],
          Key: `${prefix}/${fileName}`,
          Body: response.body,
          ContentType: 'video/mp4',
          ContentLength: size || Number(response.headers.get('content-length'))
        });
        return request.promise();
      })
      .then(data => {
        console.log(`Successfully uploaded ${fileName} to ${prefix}.`);
        resolve(data);
      });
    });
  }

  generateZoomToken() {
    const zoomPayload = {
      iss: process.env['ZOOM_API_KEY'],
      exp: ((new Date()).getTime() + 5000)
    };
    return jwt.sign(zoomPayload, process.env['ZOOM_API_SECRET']);
  }

  recordingTofilename() {
    // GMT20210429_165119_Recording.mp4
    const video = this._event.video;
    const date = new Date(video.recording_start);
    return 'GMT' +
           date.getUTCFullYear() +
           padDigits(date.getUTCMonth()+1, 2) +
           padDigits(date.getUTCDate(), 2) +
           '_' +
           padDigits(date.getUTCHours(), 2) +
           padDigits(date.getUTCMinutes(), 2) +
           padDigits(date.getUTCSeconds(), 2) +
           '_Recording.mp4';
  }
}
```