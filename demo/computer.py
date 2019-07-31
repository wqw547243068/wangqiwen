#python中的import语句是用来导入模块的，在python模块库中有着大量的模块可供使用，要想使用这些文件需要用import语句把指定模块导入到当前程序中。
import re#处理字符串的模块，如查找特定字符，删除特定字符，字符串分割等
import tkinter#Tkinter模块("Tk 接口")是Python的标准Tk GUI工具包的接口，位Python的内置模块，直接import tkinter即可使用。
import tkinter.messagebox#调用tkinter模块中的messagebox函数，这个是消息框，对话框的关键，会弹出一个小框

#按钮操作，点击按钮后需要做的处理
def buttonClik(btn):
    content=contentVar.get()#获取文本框中的内容
    #如果已有内容是以小数点开头的，在前面加0
    if content.startswith('.'):
        content='0'+content#字符串可以直接用+来增加字符
    #根据不同的按钮作出不同的反应
    if btn in '0123456789':
        content+=btn#0-9中哪个键按下了，就在content字符串中增添
    elif btn=='.':
        #re.split，支持正则及多个字符切割
        lastPart=re.split(r'\+|-|\*|/',content)[-1]#将content从+-*/这些字符的地方分割开来，[-1]表示获取最后一个字符
        if '.'in lastPart:
            tkinter.messagebox.showerror('错误','重复出现的小数点')#出现对话框，并提示信息
            return
        else:
            content+=btn
    elif btn=='C':
        content=''#清除文本框
    elif btn=='=':
        try:
            #对输入的表达式求值
            content=str(eval(content))#调用函数eval，用字符串计算出结果
        except:
            tkinter.messagebox.showerror('错误','表达式有误')
            return
    elif btn in operators:
        if content.endswith(operators):#如果content中最后出现的+-*/
            tkinter.messagebox.showerror('错误','不允许存在连续运算符')
            return
        content+=btn
    elif btn=='Sqrt':
        n=content.split('.')#从.处分割存入n，n是一个列表
        if all(map(lambda x:x.isdigit(),n)):#如果列表中所有的都是数字，就是为了检查表达式是不是正确的
            content=eval(content)**0.5
        else:
            tkinter.messagebox.showerror('错误','表达式错误')
            return
    contentVar.set(content)#将结果显示到文本框中

root=tkinter.Tk()#生成主窗口，用root表示，后面就在root操作
#设置窗口大小和位置
root.geometry('300x270+400+100')#指定主框体大小
#不允许改变窗口大小
root.resizable(False,False)#框体大小可调性，分别表示x,y方向的可变性；
#设置窗口标题
root.title('计算器')

#文本框和按钮都是tkinter中的组件
#Entry        　　 文本框（单行）；
#Button        　　按钮；
#放置用来显示信息的文本框，设置为只读
#tkinter.StringVar    能自动刷新的字符串变量，可用set和get方法进行传值和取值
contentVar=tkinter.StringVar(root,'')
contentEntry=tkinter.Entry(root,textvariable=contentVar)#括号里面，可见第一个都是root,即表示都是以root为主界面的，将文本框中的内容存在contentVar中
contentEntry['state']='readonly'#文本框只能读，不能写
contentEntry.place(x=10,y=10,width=280,height=20)#文本框在root主界面的xy坐标位置，以及文本框自生的宽和高
#x:        　　　 组件左上角的x坐标；
#y:        　　   组件右上角的y坐标；
#放置清除按钮和等号按钮
btnClear=tkinter.Button(root,text='C',bg = 'red',command=lambda:buttonClik('C'))#在root主界面中放置按钮，按钮上显示C，红色，点击按钮后进入buttonClik回调函数做进一步的处理，注意传入了参数‘C’，这样就能分清是哪个按钮按下了
#下面的内容和上面的模式都是一样的
btnClear.place(x=40,y=40,width=80,height=20)
btnCompute=tkinter.Button(root,text='=',bg = 'yellow',command=lambda :buttonClik('='))
btnCompute.place(x=170,y=40,width=80,height=20)

#放置10个数字、小数点和计算平方根的按钮
digits=list('0123456789.')+['Sqrt']#序列list是Python中最基本的数据结构。序列中的每个元素都分配一个数字 - 它的位置，或索引，第一个索引是0，第二个索引是1，依此类推。
index=0
#用循环的方式将上面数字、小数点、平方根这12个按钮分成四行三列进行放置
for row in range(4):
    for col in range(3):
        d=digits[index]#按索引从list中取值，和c语言中的数组类似
        index+=1#索引号递增
        btnDigit=tkinter.Button(root,text=d,command=lambda x=d:buttonClik(x))#和上面的是类似的
        btnDigit.place(x=20+col*70,y=80+row*50,width=50,height=20)#很显然，每次放一个按钮的位置是不一样的，但是它们之间的关系时确定的
#放置运算符按钮
operators=('+','-','*','/','**','//')#Python的元组与列表类似，不同之处在于元组的元素不能修改。
#元组使用小括号，列表使用方括号。
#enumerate() 函数用于将一个可遍历的数据对象(如列表、元组或字符串)组合为一个索引序列，同时列出数据和数据下标，一般用在 for 循环当中。
for index,operator in enumerate(operators):
    btnOperator=tkinter.Button(root,text=operator,bg = 'orange',command=lambda x=operator:buttonClik(x))#创建的过程和上面类似
    btnOperator.place(x=230,y=80+index*30,width=50,height=20)

root.mainloop()#进入消息循环（必需组件）
