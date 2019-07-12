#!/opt/anaconda3/bin/python


from __future__ import absolute_import
from __future__ import division

import os
import random
import numpy as np
import tensorflow as tf

from build_graph import build_graph, NUM_FRAMES, IMAGE_SIZE
from load_dataset import load_exercise_dataset
from process_video import rgb_data, flow_data


_CHECK_EVERY = 20

_VIDEO_DIR = 'videos'
_LABEL_MAP_PATH = 'data/exercises_label_map.txt'

_CHECKPOINT_PATHS = {
  'rgb_imagenet': 'data/checkpoints/rgb_imagenet/model.ckpt',
  'flow_imagenet': 'data/checkpoints/flow_imagenet/model.ckpt',
  'training': 'data/checkpoints/training/model.ckpt'
}

_STATS = {
  'train_acc': 'data/stats/train_acc.npy',
  'val_acc': 'data/stats/val_acc.npy',
  'loss': 'data/stats/loss.npy'
}

os.environ['TF_CPP_MIN_LOG_LEVEL'] = '2'


def train(num_epochs, beta, lr, evaluate_test_dset=False):
  tf.logging.set_verbosity(tf.logging.INFO)
  tf.reset_default_graph()

  inputs, outputs, savers, tf_summaries = build_graph(beta=beta)
  learning_rate, rgb_input, flow_input, is_training, y = inputs
  scores, loss, loss_minimize = outputs
  rgb_saver, flow_saver, training_saver = savers

  # Load the training and test data
  X_train_initial, X_test, y_train_initial, y_test = load_exercise_dataset(_VIDEO_DIR, _LABEL_MAP_PATH)
  X_train_initial, y_train_initial = np.array(X_train_initial), np.array(y_train_initial)
  dset_size = X_train_initial.shape[0]
  validation_cutoff = int(dset_size * 0.2)
  test_dset = list(zip(X_test, y_test))

  print('\ntrain_dset len={}; val_dset len={}; test_dset len={}\n'.format(
    dset_size - validation_cutoff, validation_cutoff, len(test_dset)
  ))

  try:
    train_accuracies = np.load(_STATS['train_acc']).tolist()
    val_accuracies = np.load(_STATS['val_acc']).tolist()
    losses = np.load(_STATS['loss']).tolist()
    tf.logging.info('Statistics restored')
  except:
    train_accuracies, val_accuracies, losses = [], [], []


  def _check_acc(msg, dset, sess):
    num_correct, num_samples = 0, 0

    for x_video, y_class in dset:
      feed_dict = {
        rgb_input: rgb_data(x_video, IMAGE_SIZE, nframes=NUM_FRAMES),
        flow_input: flow_data(x_video, IMAGE_SIZE, nframes=NUM_FRAMES),
        is_training: 0
      }

      scores_np = sess.run(scores, feed_dict=feed_dict)
      y_pred = scores_np.argmax(axis=1)
      num_samples += 1
      num_correct += (y_pred == y_class).sum()

    acc = float(num_correct) / num_samples
    print('%s: %d / %d correct (%.2f%%)' % (msg, num_correct, num_samples, 100 * acc))
    return acc


  if not os.path.exists('summaries'):
    os.mkdir('summaries')
  path = os.path.join('summaries', 'first')
  if not os.path.exists(path):
    os.mkdir(path)

  # Now we can run the computational graph many times to train the model.
  # When we call sess.run we ask it to evaluate train_op, which causes the
  # model to update.
  with tf.Session() as sess:
    writer = tf.summary.FileWriter(path, sess.graph)
    sess.run(tf.global_variables_initializer())

    rgb_saver.restore(sess, _CHECKPOINT_PATHS['rgb_imagenet'])
    tf.logging.info('RGB checkpoint restored')
    flow_saver.restore(sess, _CHECKPOINT_PATHS['flow_imagenet'])
    tf.logging.info('Flow checkpoint restored')
    try:
      training_saver.restore(sess, _CHECKPOINT_PATHS['training'])
      tf.logging.info('Training checkpoint restored')
    except Exception as e:
      pass

    if evaluate_test_dset:
      _ = _check_acc('Test', test_dset, sess)
      exit()

    t = 0

    for epoch in range(num_epochs):
      print('Starting epoch %d' % epoch)

      # Re-sample train and validation datasets for each epoch
      nums = list(range(dset_size))
      indices = random.sample(nums, validation_cutoff)
      mask = np.ones(dset_size, np.bool)
      mask[indices] = 0
      X_train, y_train = X_train_initial[mask], y_train_initial[mask]
      train_dset = list(zip(X_train, y_train))
      X_val, y_val = X_train_initial[indices], y_train_initial[indices]
      val_dset = list(zip(X_val, y_val))

      if epoch != 0:
        # Check training and validation accuracies, and save the model
        save_path = training_saver.save(sess, _CHECKPOINT_PATHS['training'])
        print('\nTraining model saved in path: %s' % save_path)

        train_acc = _check_acc('Train', train_dset, sess)
        val_acc = _check_acc('Val', val_dset, sess)

        train_accuracies.append(train_acc)
        val_accuracies.append(val_acc)

        np.save(_STATS['train_acc'], np.array(train_accuracies))
        np.save(_STATS['val_acc'], np.array(val_accuracies))
        np.save(_STATS['loss'], np.array(losses))

      for x_video, y_class in train_dset:
        feed_dict = {
          learning_rate: lr,
          rgb_input: rgb_data(x_video, IMAGE_SIZE, nframes=NUM_FRAMES),
          flow_input: flow_data(x_video, IMAGE_SIZE, nframes=NUM_FRAMES),
          y: np.array([y_class]),
          is_training: 1
        }

        if t % _CHECK_EVERY == 0:
            ops = [loss, loss_minimize, tf_summaries]
            loss_np, _, summary = sess.run(ops, feed_dict=feed_dict)
            writer.add_summary(summary, epoch)
        else:
            ops = [loss, loss_minimize]
            loss_np, _ = sess.run(ops, feed_dict=feed_dict)

        losses.append(loss_np)

        print('Iteration %d, loss = %.4f' % (t, loss_np))
        t += 1


if __name__ == '__main__':
  train(num_epochs=25, beta=0.25, lr=5e-4, evaluate_test_dset=False)
