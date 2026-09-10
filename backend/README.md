# KAMNDER AI generation backend

This service is the GPU-side adapter used by the Android client. It should run an open-source model such as Wan2.1 and expose a small HTTP API.

## API contract

`POST /generate`

```json
{
  "mode": "text_to_video",
  "prompt": "A cinematic sunset over the ocean",
  "image_url": null,
  "model": "Wan2.1",
  "size": "1280x720",
  "fps": 30
}
```

The Android app sends jobs here; the model is not bundled into the APK. This keeps the APK practical for phones such as the POCO M4 Pro.

Wan2.1 supports text-to-video, image-to-video and text-to-image. Its official implementation supports 720p with the 14B T2V model; the lighter 1.3B model is recommended at 480p for more stable results.
