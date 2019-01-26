#https://blog.csdn.net/winycg/article/details/79468320
import numpy as np
import random
import tensorflow as tf
import gym
 
max_episode = 100
env = gym.make('CartPole-v0')
env = env.unwrapped
 
 
class DeepQNetwork(object):
    def __init__(self,
                 n_actions,
                 n_features,
                 learning_rate=0.01,
                 reward_decay=0.9,  # gamma
                 epsilon_greedy=0.9,  # epsilon
                 epsilon_increment = 0.001,
                 replace_target_iter=300,  # 更新target网络的间隔步数
                 buffer_size=500,  # 样本缓冲区
                 batch_size=32,
                 ):
        self.n_actions = n_actions
        self.n_features = n_features
        self.lr = learning_rate
        self.gamma = reward_decay
        self.epsilon_max = epsilon_greedy
        self.replace_target_iter = replace_target_iter
        self.buffer_size = buffer_size
        self.buffer_counter = 0  # 统计目前进入过buffer的数量
        self.batch_size = batch_size
        self.epsilon = 0 if epsilon_increment is not None else epsilon_greedy
        self.epsilon_max = epsilon_greedy
        self.epsilon_increment = epsilon_increment
        self.learn_step_counter = 0  # 学习计步器
        self.buffer = np.zeros((self.buffer_size, n_features * 2 + 2))  # 初始化Experience buffer[s,a,r,s_]
        self.build_net()
        # 将eval网络中参数全部更新到target网络
        target_params = tf.get_collection(tf.GraphKeys.GLOBAL_VARIABLES, scope='target_net')
        eval_params = tf.get_collection(tf.GraphKeys.GLOBAL_VARIABLES, scope='eval_net')
        with tf.variable_scope('soft_replacement'):
            self.target_replace_op = [tf.assign(t, e) for t, e in zip(target_params, eval_params)]
        self.sess = tf.Session()
        tf.summary.FileWriter('logs/', self.sess.graph)
        self.sess.run(tf.global_variables_initializer())
 
    def build_net(self):
        self.s = tf.placeholder(tf.float32, [None, self.n_features])
        self.s_ = tf.placeholder(tf.float32, [None, self.n_features])
        self.r = tf.placeholder(tf.float32, [None, ])
        self.a = tf.placeholder(tf.int32, [None, ])
 
        w_initializer = tf.random_normal_initializer(0., 0.3)
        b_initializer = tf.constant_initializer(0.1)
        # q_eval网络架构，输入状态属性，输出4种动作
        with tf.variable_scope('eval_net'):
            eval_layer = tf.layers.dense(self.s, 20, tf.nn.relu, kernel_initializer=w_initializer,
                                         bias_initializer=b_initializer, name='eval_layer')
            self.q_eval = tf.layers.dense(eval_layer, self.n_actions, kernel_initializer=w_initializer,
                                          bias_initializer=b_initializer, name='output_layer1')
        with tf.variable_scope('target_net'):
            target_layer = tf.layers.dense(self.s_, 20, tf.nn.relu, kernel_initializer=w_initializer,
                                           bias_initializer=b_initializer, name='target_layer')
            self.q_next = tf.layers.dense(target_layer, self.n_actions, kernel_initializer=w_initializer,
                                          bias_initializer=b_initializer, name='output_layer2')
        with tf.variable_scope('q_target'):
            # 计算期望价值，并使用stop_gradient函数将其不计算梯度，也就是当做常数对待
            self.q_target = tf.stop_gradient(self.r + self.gamma * tf.reduce_max(self.q_next, axis=1))
        with tf.variable_scope('q_eval'):
            # 将a的值对应起来，
            a_indices = tf.stack([tf.range(tf.shape(self.a)[0]), self.a], axis=1)
            self.q_eval_a = tf.gather_nd(params=self.q_eval, indices=a_indices)
        with tf.variable_scope('loss'):
            self.loss = tf.reduce_mean(tf.squared_difference(self.q_target, self.q_eval_a))
        with tf.variable_scope('train'):
            self.train_op = tf.train.RMSPropOptimizer(self.lr).minimize(self.loss)
 
            # 存储训练数据
 
    def store_transition(self, s, a, r, s_):
        transition = np.hstack((s, a, r, s_))
        index = self.buffer_counter % self.buffer_size
        self.buffer[index, :] = transition
        self.buffer_counter += 1
 
    def choose_action_by_epsilon_greedy(self, status):
        status = status[np.newaxis, :]
        if random.random() < self.epsilon:
            actions_value = self.sess.run(self.q_eval, feed_dict={self.s: status})
            action = np.argmax(actions_value)
        else:
            action = np.random.randint(0, self.n_actions)
        return action
 
    def learn(self):
        # 每学习self.replace_target_iter步，更新target网络的参数
        if self.learn_step_counter % self.replace_target_iter == 0:
            self.sess.run(self.target_replace_op)
            # 从Experience buffer中选择样本
        sample_index = np.random.choice(min(self.buffer_counter, self.buffer_size), size=self.batch_size)
        batch_buffer = self.buffer[sample_index, :]
        _, cost = self.sess.run([self.train_op, self.loss], feed_dict={
            self.s: batch_buffer[:, :self.n_features],
            self.a: batch_buffer[:, self.n_features],
            self.r: batch_buffer[:, self.n_features + 1],
            self.s_: batch_buffer[:, -self.n_features:]
        })
        self.epsilon = min(self.epsilon_max, self.epsilon + self.epsilon_increment)
        self.learn_step_counter += 1
        return cost
 

RL = DeepQNetwork(n_actions=env.action_space.n,
                  n_features=env.observation_space.shape[0])
total_step = 0
for episode in range(max_episode):
    observation = env.reset()
    episode_reward = 0
    while True:
        env.render()  # 表达环境
        action = RL.choose_action_by_epsilon_greedy(observation)
        observation_, reward, done, info = env.step(action)
        # x是车的水平位移，theta是杆离垂直的角度
        x, x_dot, theta, theta_dot = observation_
        # reward1是车越偏离中心越少
        reward1 = (env.x_threshold - abs(x))/env.x_threshold - 0.8
        # reward2为杆越垂直越高
        reward2 = (env.theta_threshold_radians - abs(theta))/env.theta_threshold_radians - 0.5
        reward = reward1 + reward2
        RL.store_transition(observation, action, reward, observation_)
        if total_step > 100:
            cost = RL.learn()
            print('cost: %.3f' % cost)
        episode_reward += reward
        observation = observation_
        if done:
            print('episode:', episode,
                  'episode_reward %.2f' % episode_reward,
                  'epsilon %.2f' % RL.epsilon)
            break
        total_step += 1

# mountain car
RL = DeepQNetwork(n_actions=env.action_space.n,
                  n_features=env.observation_space.shape[0])
total_step = 0
for episode in range(max_episode):
    observation = env.reset()
    episode_reward = 0
    while True:
        env.render()  # 表达环境
        action = RL.choose_action_by_epsilon_greedy(observation)
        observation_, reward, done, info = env.step(action)
        #
        position, velocity = observation_
        reward=abs(position+0.5)
        RL.store_transition(observation, action, reward, observation_)
        if total_step > 100:
            cost_ = RL.learn()
            cost.append(cost_)
        episode_reward += reward
        observation = observation_
        if done:
            print('episode:', episode,
                  'episode_reward %.2f' % episode_reward,
                  'epsilon %.2f' % RL.epsilon)
            break
        total_step += 1
plt.plot(np.arange(len(cost)), cost)
plt.show()
 
