#!/usr/bin/python3
# Zhang, Kaixu kareyzhang.gmail.com
import argparse
import sys
import json
import time

class Weights(dict): # 管理平均感知器的权重
    def __init__(self):
        self._step=0
        self._acc=dict()
    def update_weights(self,key,delta): # 更新权重
        if key not in self : self[key]=0
        self[key]+=delta
        if key not in self._acc : self._acc[key]=0
        self._acc[key]+=self._step*delta
    def average(self): # 平均
        for k,v in self._acc.items():
            self[k]=self[k]-self._acc[k]/self._step
    def save(self,filename):
        json.dump({k:v for k,v in self.items() if v!=0.0},
                open(filename,'w'),
                ensure_ascii=False,indent=1)
    def load(self,filename):
        self.update(json.load(open(filename)))

class CWS :
    def __init__(self):
        self.weights=Weights()
    def gen_features(self,x): # 枚举得到每个字的特征向量
        for i in range(len(x)):
            left2=x[i-2] if i-2 >=0 else '#'
            left1=x[i-1] if i-1 >=0 else '#'
            mid=x[i]
            right1=x[i+1] if i+1<len(x) else '#'
            right2=x[i+2] if i+2<len(x) else '#'
            features=['1'+mid,'2'+left1,'3'+right1,
                    '4'+left2+left1,'5'+left1+mid,'6'+mid+right1,'7'+right1+right2]
            yield features
    def update(self,x,y,delta): # 更新权重
        for i,features in zip(range(len(x)),self.gen_features(x)):
            for feature in features :
                self.weights.update_weights(str(y[i])+feature,delta)
        for i in range(len(x)-1):
            self.weights.update_weights(str(y[i])+':'+str(y[i+1]),delta)
    def decode(self,x): # 类似隐马模型的动态规划解码算法
        # 类似隐马模型中的转移概率
        transitions=[ [self.weights.get(str(i)+':'+str(j),0) for j in range(4)]
                for i in range(4) ]
        # 类似隐马模型中的发射概率
        emissions=[ [sum(self.weights.get(str(tag)+feature,0) for feature in features) 
            for tag in range(4) ] for features in self.gen_features(x)]
        # 类似隐马模型中的前向概率
        alphas=[[[e,None] for e in emissions[0]]]
        for i in range(len(x)-1) :
            alphas.append([max([alphas[i][j][0]+transitions[j][k]+emissions[i+1][k],j]
                                        for j in range(4))
                                        for k in range(4)])
        # 根据alphas中的“指针”得到最优序列
        alpha=max([alphas[-1][j],j] for j in range(4))
        i=len(x)
        tags=[]
        while i :
            tags.append(alpha[1])
            i-=1
            alpha=alphas[i][alpha[1]]
        return list(reversed(tags))

def load_example(words): # 词数组，得到x，y
    y=[]
    for word in words :
        if len(word)==1 : y.append(3)
        else : y.extend([0]+[1]*(len(word)-2)+[2])
    return ''.join(words),y

def dump_example(x,y) : # 根据x，y得到词数组
    cache=''
    words=[]
    for i in range(len(x)) :
        cache+=x[i]
        if y[i]==2 or y[i]==3 :
            words.append(cache)
            cache=''
    if cache : words.append(cache)
    return words

class Evaluator : # 评价
    def __init__(self):
        self.std,self.rst,self.cor=0,0,0
        self.start_time=time.time()
    def _gen_set(self,words):
        offset=0
        word_set=set()
        for word in words:
            word_set.add((offset,word))
            offset+=len(word)
        return word_set
    def __call__(self,std,rst): # 根据答案std和结果rst进行统计
        std,rst=self._gen_set(std),self._gen_set(rst)
        self.std+=len(std)
        self.rst+=len(rst)
        self.cor+=len(std&rst)
    def report(self):
        precision=self.cor/self.rst if self.rst else 0
        recall=self.cor/self.std if self.std else 0
        f1=2*precision*recall/(precision+recall) if precision+recall!=0 else 0
        print("历时: %.2f秒 答案词数: %i 结果词数: %i 正确词数: %i F值: %.4f"
                %(time.time()-self.start_time,self.std,self.rst,self.cor,f1))

if __name__ == '__main__':
    parser = argparse.ArgumentParser(description='')
    parser.add_argument('--iteration',type=int,default=5, help='')
    parser.add_argument('--train',type=str, help='')
    parser.add_argument('--test',type=str, help='')
    parser.add_argument('--predict',type=str, help='')
    parser.add_argument('--result',type=str, help='')
    parser.add_argument('--model',type=str, help='')
    args = parser.parse_args()
    # 训练
    if args.train: 
        cws=CWS()
        for i in range(args.iteration):
            print('第 %i 次迭代'%(i+1),end=' '),sys.stdout.flush()
            evaluator=Evaluator()
            for l in open(args.train):
                x,y=load_example(l.split())
                z=cws.decode(x)
                evaluator(dump_example(x,y),dump_example(x,z))
                cws.weights._step+=1
                if z!=y :
                    cws.update(x,y,1)
                    cws.update(x,z,-1)
            evaluator.report()
        cws.weights.average()
        cws.weights.save(args.model)
    # 使用有正确答案的语料测试
    if args.test : 
        cws=CWS()
        cws.weights.load(args.model)
        evaluator=Evaluator()
        for l in open(args.test) :
            x,y=load_example(l.split())
            z=cws.decode(x)
            evaluator(dump_example(x,y),dump_example(x,z))
        evaluator.report()
    # 对未分词的句子输出分词结果
    if args.model and (not args.train and not args.test) : 
        cws=CWS()
        cws.weights.load(args.model)
        instream=open(args.predict) if args.predict else sys.stdin
        outstream=open(args.result,'w') if args.result else sys.stdout
        for l in instream:
            x,y=load_example(l.split())
            z=cws.decode(x)
            print(' '.join(dump_example(x,z)),file=outstream)
