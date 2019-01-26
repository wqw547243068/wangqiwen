#!/usr/bin/env python
# coding:utf8

# pip install tensorflow # 1.8以上
# pip install git+git://github.com/deepmind/trfl.git
import tensorflow as tf
import trfl

# Q-values for the previous and next timesteps, shape [batch_size, num_actions].
q_tm1 = tf.get_variable(
    "q_tm1", initializer=[[1., 1., 0.], [1., 2., 0.]], dtype=tf.float32)
q_t = tf.get_variable(
    "q_t", initializer=[[0., 1., 0.], [1., 2., 0.]], dtype=tf.float32)

# Action indices, discounts and rewards, shape [batch_size].
a_tm1 = tf.constant([0, 1], dtype=tf.int32)
r_t = tf.constant([1, 1], dtype=tf.float32)
pcont_t = tf.constant([0, 1], dtype=tf.float32)  # the discount factor

# Q-learning loss, and auxiliary data.
loss, q_learning = trfl.qlearning(q_tm1, a_tm1, r_t, pcont_t, q_t)

reduced_loss = tf.reduce_mean(loss)
optimizer = tf.train.AdamOptimizer(learning_rate=0.1)
train_op = optimizer.minimize(reduced_loss)

