"""
Provides functions for processing a video file into numpy arrays
for RGB data and optical flow data, which can be used with the I3D model.
"""

import cv2
import numpy as np
from matplotlib import pyplot as plt


def _raw_numpy_array(video_file, nframes=None):
  """
  Loads a video from the given file. Will set the number
  of frames to `nframes` if this parameter is not `None`.

  Returns:
  - (width, height, arr): The width and height of the video,
    and a numpy array with the parsed contents of the video.
  """

  # Read video
  cap = cv2.VideoCapture(video_file)

  # Get properties of the video
  frame_count = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
  w = cap.get(cv2.CAP_PROP_FRAME_WIDTH)
  h = cap.get(cv2.CAP_PROP_FRAME_HEIGHT)

  # Min allowed height or width (whatever is smaller), in pixels
  min_dimension = 256.0

  # Determine scaling factors of width and height
  assert min(w, h) > 0, 'Cannot resize {} with W={}, H={}'.format(video_file, w, h)
  scale = min_dimension / min(w, h)
  w = int(w * scale)
  h = int(h * scale)

  buf = np.zeros((1, frame_count, h, w, 3), np.dtype('float32'))
  fc, flag = 0, True

  while fc < frame_count and flag:
      flag, image = cap.read()

      if flag:
          image = cv2.resize(image, (w, h))
          buf[0, fc] = image

      fc += 1

  cap.release()

  if nframes is not None:
    if nframes < frame_count:
      fc = frame_count
      t1, t2 = int(fc/2) - int(nframes/2), int(fc/2) + int(nframes/2)
      buf = buf[:, t1:t2, :, :, :]
    elif nframes > frame_count:
      buf = np.resize(buf, (1, nframes, h, w, 3))

  return w, h, buf


def _crop_video(numpy_video, size, desired_size):
  """
  Crop a video of the given size (WIDTH, HEIGHT) into a square of `desired_size`.
  The video is represented as a numpy array. This func is for internal usage.
  """

  w, h = size
  h1, h2 = int(h/2) - int(desired_size/2), int(h/2) + int(desired_size/2)
  w1, w2 = int(w/2) - int(desired_size/2), int(w/2) + int(desired_size/2)
  return numpy_video[:, :, h1:h2, w1:w2, :]


def _visualize_numpy_video(vid):
  """Visualize a video using a numpy array (for internal use only)."""

  plt.axis('off')

  num_frames = vid.shape[0]
  img = plt.imshow(vid[0])

  for i in range(1, num_frames):
      img.set_data(vid[i])
      plt.pause(1.0 / 25.0)

  plt.show()


def rgb_data(video_file, size, nframes=None):
  """
  Loads a numpy array of shape (1, nframes, size, size, 3) from a video file.
  Values contained in the array are based on RGB values of each frame in the video.

  Parameter `size` should be an int (pixels) for a square cropping of the video.
  Omitting the parameter `nframes` will preserve the original # frames in the video.
  """

  # Load video into numpy array
  w, h, buf = _raw_numpy_array(video_file, nframes=nframes)

  # Scale pixels between -1 and 1
  buf[0, :] = ((buf[0, :] / 255.0) * 2) - 1

  # Select center crop from the video
  return _crop_video(buf, (w, h), size)


def flow_data(video_file, size, nframes=None):
  """
  Loads a numpy array of shape (1, nframes, size, size, 2) from a video file.
  Values contained in the array are based on optical flow of the video.
  https://docs.opencv.org/3.1.0/d6/d39/classcv_1_1cuda_1_1OpticalFlowDual__TVL1.html

  Parameter `size` should be an integer (pixels) for a square cropping of the video.
  Omitting the parameter `nframes` will preserve the original # frames in the video.
  """

  # Load video into numpy array, and crop the video
  w, h, buf = _raw_numpy_array(video_file, nframes=nframes)
  buf = _crop_video(buf, (w, h), size)

  num_frames = buf.shape[1]
  flow = np.zeros((1, num_frames, size, size, 2), dtype='float32')

  # Convert to grayscale
  buf = np.dot(buf, np.array([0.2989, 0.5870, 0.1140]))

  # Apply optical flow algorithm
  for i in range(1, num_frames):
      prev, cur = buf[0, i - 1], buf[0, i]
      cur_flow = cv2.calcOpticalFlowFarneback(prev, cur, None, 0.5, 3, 15, 3, 5, 1.2, 0)

      # Truncate values to [-20, 20] and scale from [-1, 1]
      cur_flow[cur_flow < -20] = -20
      cur_flow[cur_flow > 20] = 20
      cur_flow /= 20
      flow[0, i] = cur_flow

  return flow
