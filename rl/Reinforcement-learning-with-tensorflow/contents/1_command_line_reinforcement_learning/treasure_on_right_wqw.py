
"""
A simple example for Reinforcement Learning using table lookup Q-learning method.
An agent "o" is on the left of a 1 dimensional world, the treasure is on the rightmost location.
Run this program and to see how the agent will improve its strategy of finding the treasure.

View more on my tutorial page: https://morvanzhou.github.io/tutorials/
modified by wqw547243068@163.com, 2019-01-26
"""

import numpy as np
import pandas as pd
import time

np.random.seed(2)  # reproducible


N_STATES = 6   # 状态数目 the length of the 1 dimensional world
ACTIONS = ['left', 'right'] # 可行动作列表 available actions
EPSILON = 0.9   # 贪心因子 greedy police
ALPHA = 0.1     # 学习率 learning rate
GAMMA = 0.9    # 折扣损失 discount factor
MAX_EPISODES = 13   # 最大训练回合 maximum episodes
FRESH_TIME = 0.3    # 每回合休息时间 fresh time for one move


import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation


def render():
    """
        绘制网格图
    """
    def update_line(num, data, line):
        line.set_data(data[..., :num])
        return line,

    fig1 = plt.figure()
    data = np.random.rand(2, 25)
    l, = plt.plot([], [], 'r-')
    plt.xlim(0, 1)
    plt.ylim(0, 1)
    plt.xlabel('x')
    plt.title('test')
    line_ani = animation.FuncAnimation(fig1, update_line, 25, fargs=(data, l), interval=50, blit=True)
    plt.show()


def build_q_table(n_states, actions):
    """
        构建Q表, nXa
    """
    # Q表初始化
    table = pd.DataFrame(
        np.zeros((n_states, len(actions))),     # q_table initial values
        columns=actions,    # actions's name
    )
    # print(table)    # show table
    return table


def choose_action(state, q_table):
    """
        策略函数：如何选择下一步动作 This is how to choose an action
    """
    # 获取该状态下所有动作奖励列表
    state_actions = q_table.iloc[state, :]
    if (np.random.uniform() > EPSILON) or ((state_actions == 0).all()):  
        # 随机模式（探索）act non-greedy or state-action have no value
        action_name = np.random.choice(ACTIONS)
    else:   # 贪婪模式（利用）act greedy 
        action_name = state_actions.idxmax()
        # replace argmax to idxmax as argmax means a different function in newer version of pandas
    return action_name


def get_env_feedback(S, A):
    """
        agent从环境中获取反馈，S状态下采取A获得的奖励R
        This is how agent will interact with the environment
    """
    if A == 'right':
        # move right
        if S == N_STATES - 2:   # terminate
            S_ = 'terminal'
            R = 1
        else:
            S_ = S + 1
            R = 0
    else:
        # move left
        R = 0
        if S == 0:
            S_ = S  # reach the wall
        else:
            S_ = S - 1
    return S_, R


def update_env(S, episode, step_counter):
    # This is how environment be updated
    env_list = ['-']*(N_STATES-1) + ['T']   # '---------T' our environment
    if S == 'terminal':
        interaction = 'Episode %s: total_steps = %s' % (episode+1, step_counter)
        print(' => {}'.format(interaction))
        #print('\r{}'.format(interaction), end='')
        time.sleep(1)
        #print('\r                                ', end='')
    else:
        env_list[S] = 'o'
        interaction = ''.join(env_list)
        print('\r{}'.format(interaction), end='')
        time.sleep(FRESH_TIME)


def rl():
    # main part of RL loop
    q_table = build_q_table(N_STATES, ACTIONS)
    for episode in range(MAX_EPISODES):
        step_counter = 0
        S = 0
        is_terminated = False
        update_env(S, episode, step_counter)
        while not is_terminated:
            A = choose_action(S, q_table)
            S_, R = get_env_feedback(S, A)  # take action & get next state and reward
            q_predict = q_table.loc[S, A]
            if S_ != 'terminal':
                q_target = R + GAMMA * q_table.iloc[S_, :].max()   # next state is not terminal
            else:
                q_target = R     # next state is terminal
                is_terminated = True    # terminate this episode
            q_table.loc[S, A] += ALPHA * (q_target - q_predict)  # update
            S = S_  # move to next state
            update_env(S, episode, step_counter+1)
            step_counter += 1
    return q_table


if __name__ == "__main__":
    q_table = rl()
    print('\r\nQ-table:')
    print(q_table)
