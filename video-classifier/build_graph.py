import numpy as np
import tensorflow as tf
import sonnet as snt

import i3d


NUM_CLASSES = 6
NUM_FRAMES = 140
IMAGE_SIZE = 224

_BATCH_SIZE = 1


def _variable_summaries(var):
  mean = tf.reduce_mean(var)
  tf.summary.scalar('mean', mean)
  with tf.name_scope('stddev'):
    stddev = tf.sqrt(tf.reduce_mean(tf.square(var - mean)))
  tf.summary.scalar('stddev', stddev)
  tf.summary.scalar('max', tf.reduce_max(var))
  tf.summary.scalar('min', tf.reduce_min(var))
  tf.summary.histogram('histogram', var)


def _build_stream(stream_name, is_training):
  dims = 3 if stream_name is 'RGB' else 2
  input_shape = (_BATCH_SIZE, NUM_FRAMES, IMAGE_SIZE, IMAGE_SIZE, dims)
  inp = tf.placeholder(tf.float32, shape=input_shape)

  with tf.variable_scope(stream_name):
    model = i3d.InceptionI3d(spatial_squeeze=True, final_endpoint='Mixed_5c')
    # No training here. Don't backpropagate the main model, and no dropout.
    mixed_5c, _ = model(inp, is_training=False, dropout_keep_prob=1.0)

  var_map = {}
  for var in tf.global_variables():
    if var.name.split('/')[0] == stream_name:
      var_map[var.name.replace(':0', '')] = var

  saver = tf.train.Saver(var_list=var_map, reshape=True)

  with tf.variable_scope(stream_name):
    net = tf.nn.avg_pool3d(mixed_5c, ksize=[1, 2, 7, 7, 1],
                           strides=[1, 1, 1, 1, 1], padding=snt.VALID)
    logit_fn = i3d.Unit3D(output_channels=NUM_CLASSES,
                          kernel_shape=[1, 1, 1],
                          activation_fn=None,
                          use_batch_norm=False,
                          use_bias=True,
                          regularizers={'w': tf.nn.l2_loss},
                          name='Conv3d_0c_1x1')
    logits = logit_fn(net, is_training=is_training)
    logits = tf.squeeze(logits, [2, 3], name='SpatialSqueeze')
  logits = tf.reduce_mean(logits, axis=1)

  custom_vars = {}
  for var in tf.global_variables():
    name = var.name.replace(':0', '')
    if var.name.split('/')[0] == stream_name and name not in var_map.keys():
      custom_vars[name] = var
      with tf.name_scope(name):
        _variable_summaries(var)

  return (inp, logits, saver, custom_vars)


def build_graph(beta):
  is_training = tf.placeholder(tf.bool, name='is_training')
  y = tf.placeholder(tf.int32, (_BATCH_SIZE, ))

  # Compute streams for RGB and Flow
  rgb_stream = _build_stream('RGB', is_training)
  flow_stream = _build_stream('Flow', is_training)
  rgb_input, rgb_logits, rgb_saver, rgb_vars = rgb_stream
  flow_input, flow_logits, flow_saver, flow_vars = flow_stream

  # Combine streams
  logits = rgb_logits + flow_logits

  # Compute loss using Softmax from logits
  with tf.name_scope('loss'):
    loss = tf.nn.sparse_softmax_cross_entropy_with_logits(labels=y, logits=logits)
    tf.summary.scalar('loss_no_reg', tf.squeeze(loss))
    reg_losses = tf.get_collection(tf.GraphKeys.REGULARIZATION_LOSSES)
    loss = tf.reduce_mean(loss + beta * sum(reg_losses))
    tf.summary.scalar('loss_reg', tf.squeeze(loss))

  # Use optimizer to compute gradients
  learning_rate = tf.placeholder(tf.float32, shape=None, name='learning_rate')
  optimizer = tf.train.AdamOptimizer(learning_rate=learning_rate)
  grads_and_vars = optimizer.compute_gradients(loss)
  loss_minimize = optimizer.minimize(loss)

  training_saver_vars = {**rgb_vars, **flow_vars}
  training_saver = tf.train.Saver(var_list=training_saver_vars, reshape=True)

  inputs = (learning_rate, rgb_input, flow_input, is_training, y)
  outputs = (logits, loss, loss_minimize)
  savers = (rgb_saver, flow_saver, training_saver)
  summaries = tf.summary.merge_all()
  return (inputs, outputs, savers, summaries)
