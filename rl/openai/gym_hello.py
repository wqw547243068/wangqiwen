import gym
env = gym.make('CartPole-v0')
env.reset() #重置环境状态
for _ in range(1000):
    env.render() #重绘每一帧
    env.step(env.action_space.sample()) # take a random action