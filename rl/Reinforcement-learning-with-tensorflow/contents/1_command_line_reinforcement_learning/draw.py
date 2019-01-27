import numpy as np
import matplotlib.pyplot as plt
import matplotlib.animation as animation


def update_line(num, data, line):
    line.set_data(data[..., :num])
    return line,

fig = plt.figure()
ax = fig.add_subplot(111)


def update(icon_list):
    #icon_list = ['-', 'o', '-', '-', 'T', '-']
    print(icon_list)
    # plt.clf()
    list_len = len(icon_list)
    delta = 0.9/list_len
    color_dict = {'-':'g', 'o':'b', 'T':'r'}
    start_point = (0.05, 0.05)
    plt.text(0.5, 0.6, 'Episode 5', horizontalalignment='center',  fontsize=12,
            verticalalignment='center', transform=ax.transAxes)
    for idx, item in enumerate(icon_list):
        color_value = color_dict[item]
        end_point = (start_point[0]+idx*delta, 0.3)
        ax.add_patch(plt.Rectangle((end_point[0], end_point[1]+delta), delta, delta*0.5, 
            linestyle='--', edgecolor='b', linewidth=1, alpha=0.5))
        plt.text(end_point[0]+0.5*delta, end_point[1]+1.25*delta, idx, horizontalalignment='center',  fontsize=12,
            verticalalignment='center', transform=ax.transAxes)
        ax.add_patch(plt.Rectangle(end_point, delta, delta, 
            color='%s'%(color_value), linestyle='--', edgecolor='y', linewidth=1, alpha=0.5)) #, fill=None
        plt.text(end_point[0]+0.5*delta, end_point[1]+0.5*delta, item, horizontalalignment='center',  fontsize=12,
            verticalalignment='center', transform=ax.transAxes)
    # plt.show()
#ax.add_patch(plt.Rectangle((0.1,0.1),0.3,0.3))
def init():
    plt.xlim(0, 1)
    plt.ylim(0, 1)
    plt.xlabel('x')
    plt.title('test')
    return l,

data = [['-', 'o', '-', '-', 'T', '-'],
    ['-', '-', 'o', '-', 'T', '-'],
    ['-', '-', '-', 'o', 'T', '-']]
# l, = plt.plot([], [], 'r-')
# line_ani = animation.FuncAnimation(fig, update, data, interval=10, blit=True)
for item in data:
    update(item)
plt.show()