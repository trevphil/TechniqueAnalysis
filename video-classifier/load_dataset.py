"""Load a dataset of exercises. No video pre-processing is done here."""

import os
from os import path
from sklearn.model_selection import train_test_split


def _label(filename):
  """Derives a class label from a filename"""

  filename_no_ext = filename[:filename.rfind('.')]
  filename_no_uuid = filename_no_ext[:filename_no_ext.rfind('_')]
  return filename_no_uuid


def load_exercise_dataset(dataset_dir, label_map_path):
  """
  Loads a dataset of videos of people doing exercises. The filename
  of the video is matched against the list of classes in order to
  determine the correct class label for each video.

  Parameters:
  - dataset_dir (string): path to a directory with videos
  - label_map_path (string): path to file with class labels

  Returns:
  - A tuple (X_train, X_test, y_train, y_test) where the y values
    are class indices for the X values. Each X value is a string
    pointing to the file path of a video.
  """

  assert path.isdir(dataset_dir), 'Invalid directory for dataset'
  assert path.isfile(label_map_path), 'Invalid label map path'

  invalid = ['.DS_Store', '.', '..']
  filenames = [f for f in os.listdir(dataset_dir) if f not in invalid]
  X = [path.join(dataset_dir, f) for f in filenames]

  classes = [x.strip() for x in open(label_map_path)]
  y = [classes.index(_label(f)) for f in filenames]

  # Split the data into train/test
  return train_test_split(X, y, test_size=0.2, shuffle=True)
