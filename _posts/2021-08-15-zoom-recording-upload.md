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

# Second attempt: AWS Lambda
I regretfully abandoned the Zapier approach, and decided to bite the bullet and write new code to perform my function. For deployment simplicity, I chose to write it using the [serverless Node.js framework](https://www.serverless.com/) and to host it on AWS Lambda.

# Planning the function
The Zoom API provides webhook notifications about events in a Zoom account. To setup a webhook integration, I created a Zoom Marketplace app of type JWT (JSON Web Token) and added to it an event subscription for the [Recording Completed event](https://marketplace.zoom.us/docs/api-reference/webhook-reference/recording-events/recording-completed). Each event subscription accepts a single webhook endpoint, which is the URL of the AWS Lambda HTTP endpoint.

The plan of the function is thus:
- Upon reception of the webhook,
- Don't continue unless it's a legitimate course meeting
- Select the eligible video files to be uploaded
- Create the appropriate video folder in a configured AWS S3 bucket
- Generate a short-lived JWT for the Zoom video file download
- For each video file,
- Generate a filename
- Download the video file from Zoom
- Upload the video file to S3, without creating an intermediate file in the Lambda environment

# Third attempt: Single function
My first attempt was to implement the outline above in a single function that loops over the video files and uploads them sequentially. I was very proud of writing a streaming file download/upload loop that does not need intermediate storage, as follows:

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

<script src="https://gist.github.com/infojunkie/704508f9c0a55999f9b1418844e02682.js"></script>
