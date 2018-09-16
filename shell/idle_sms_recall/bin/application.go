package smspush

import (
	"flag"
	"log"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
	"bufio"
	"io"
	"math/rand"
	"encoding/json"
	"fmt"

	//"github.com/pquerna/ffjson/ffjson"

	"backend/config"
	"backend/gateway/sms/service"
	"backend/slog"
	"backend/version"
	"backend/gateway/eventlogclient"
	"backend/domain/eventlog"
)

var (
	configPath  = flag.String("config", "/etc/putong/config.json", "Path to configuration file.")
	pushFile = flag.String("push","push.txt","Push information including desitination user and debug")
	sendUserFile  = flag.String("send", "data/sendUser.txt", "File stored the users to send.")
	doneUserFile  = flag.String("done", "data/doneUser.txt", "File saved the users sended.")
	errorUserFile  = flag.String("error", "data/errorUser.txt", "File saved the error users.")
	mode = flag.String("mode", "debug", "debug mode, or online mode")
	pushMinutes = flag.Int64("pushMinutes", 0, "the duration to push")

	sender *service.Sender

	pushTime time.Duration
	//Configure info for current job
    pushInfo = map[string]string{} // read from pushFile
    devSet = [][]string{} // developer & tester info
    userSet = []map[string]string{} // real user info
    sendFormat = []string{} // input data format
	sendFormatLen = 0
    copyWriteInfo = map[string][]string{}	// copyWrite info
    copyWriteDict = map[string][]map[string]string{}	// copyWrite dict
	copyWriteNum = 0
	groupNum = 0
	nameTruncate = "no"
	kafkaTopic = "idle-sms-recall" // Kafka topic name
	kafkaServer = "127.0.0.1:2181" // Kafka topic name
	bufferNum = 100 // Caching users to redis
	provider = "-" //短信运营商名称
	status = "-" //短信发送返回状态(success,fail)
	output_str = "user_id,phone,net,name,gender,group,cwType"
	otherFormat = []string{}
)


func readConf(fileName string , confInfo map[string]string) error {
    f, err := os.Open(fileName)
    if err != nil {
        return err
    }
	defer f.Close()
    buf := bufio.NewReader(f)
    for {
        line, err := buf.ReadString('\n')
        if err != nil {
            if err == io.EOF {
                return nil
            }
            return err
        }
        line = strings.TrimSpace(line)
        //判空操作必须在io.EOF之后,否则僵死
        //if line == "" {continue}
        if strings.Index(line,"=") == -1 {continue}
        //if !strings.Contains(line,"=") { continue }
        if strings.HasPrefix(line,"#") { continue }
        arr := strings.Split(line,"=")
        if len(arr) != 2 {
            continue
        }
        key  := strings.TrimSpace(arr[0])
        value := strings.TrimSpace(arr[1])
        if key == "copyWriteMale" || key == "copyWriteFemale" {
            arr = strings.Split(value,"$$")
            for i,v := range arr {
                arr[i] = strings.TrimSpace(v)
            }
            value = strings.Join(arr,"$$")
        }
        confInfo[key] = value
    }
    return nil
}

func readData(fileName string , dataInfo *[]map[string]string) error {
    f, err := os.Open(fileName)
    if err != nil {
        return err
    }
	defer f.Close()
    buf := bufio.NewReader(f)
    for {
        line, err := buf.ReadString('\n')
        if err != nil {
            if err == io.EOF {
                return nil
            }
            return err
        }
        line = strings.TrimSpace(line)
		//arr := strings.Split(line,",")
		arr := strings.Split(line,"\t")
        if len(arr) != sendFormatLen { //Alert 级别高于 Err
			log.Fatalf("待发送用户数据格式异常(%v!=%v),%v", len(arr),sendFormatLen,arr)
			//slog.Alert("Len of user data illegal (%v!=%v),%v", len(arr),sendFormatLen,arr)
            continue
        }
		cur_user := map[string]string{}
		for i,v := range arr {
			cur_user[sendFormat[i]] = v
		}
		//slog.Info("line=[%v],arr=[%v],cur_user=[%v]",line,arr,cur_user)
		//group取值越界
		idx, _ := strconv.Atoi(cur_user["group"])
		if idx > groupNum-1 || idx < 0 {
			log.Fatalf("Groupid取值有误,越界,(%v>=%v)", idx,groupNum-1)
			//slog.Err("Group id error ! (%v>=%v)", idx,groupNum-1)
			continue
		}
		// name truncation
		if nameTruncate == "yes" {
			if r := []rune(cur_user["name"]); len(r) > 5 {
				cur_user["name"] = string(r[:5]) + "..."
			}
		}
        *dataInfo = append(*dataInfo,cur_user)
		//slog.Info("len=%v,set=%v",len(*dataInfo),*dataInfo)
    }
    return nil
}


func init() {
	version.Init()
	flag.Parse()
	if err := config.ParseGlobal(*configPath); err != nil {
		log.Fatalf("[ERROR] 配置文件读取失败! %v",err)
	}
	if err := slog.Init(config.Conf.Log); err != nil {
		log.Fatalf("[ERROR] slog初始化失败! %v",err)
	}
	log.Printf("[INFO] 读程序参数")
	sender = service.NewSender(config.Conf.Sms.BaseUrl)
	pushTime = time.Duration(*pushMinutes) * time.Minute
	//Read configure info for current push job
	log.Printf("[INFO] 加载push配置文件(pushFile=%s)",*pushFile)
    readConf(*pushFile,pushInfo)
    for k,v := range pushInfo {
		log.Printf("[INFO] 配置信息: %s => %s",k,v)
        switch k {
        case "copyWriteName": copyWriteInfo["name"] = []string{v}
        case "copyWriteVar": copyWriteInfo["var"] = strings.Split(v,",")
        case "copyWriteMale": copyWriteInfo["male"] = strings.Split(v,"$$")
        case "copyWriteFemale": copyWriteInfo["female"] = strings.Split(v,"$$")
        case "devSet":
            arr1 := strings.Split(v,";")
            for _,val := range arr1 { // phone,name
                arr2 := strings.Split(val,",")
                if len(arr2) < 2 {continue}
                devSet = append(devSet,arr2)
            }
        case "sendFormat": // user_id,phone,name,gender,group,newNum
            sendFormat = strings.Split(v,",")
			sendFormatLen = len(sendFormat)
		case "nameTruncate": nameTruncate = v
		case "kafkaTopic": kafkaTopic = v
		case "groupNum":
			tmp_int,err := strconv.Atoi(v)
			if err == nil {
				if tmp_int > 0 { groupNum=tmp_int; } //[2017-07-12]多组,小流量
			}else{
				log.Fatalf("[ERROR] 配置文件分组数(%v)非整数! %v",v,err)
			}
        }
    }
	//Check group num
	maleNum := len(copyWriteInfo["male"])
	femaleNum := len(copyWriteInfo["female"])
	if maleNum != femaleNum {
		log.Fatalf("[ERROR] 男女文案数目不一致! (male:%s != female:%s)",maleNum,femaleNum)
		//log.Fatalf("[ERROR] CopyWrite number error ! (male:%s != female:%s)",maleNum,femaleNum)
	}
	//groupNum = maleNum
	copyWriteNum = len(copyWriteInfo["male"])
	//[2017-06-21]Copywrite,支持组内多文案
	//copyWriteDict := map[string][]map[string]string{}    // copyWrite dict
	for _,gen := range []string{"male","female"} {
		for idx,cw := range  copyWriteInfo[gen]{
			copyWriteDict[gen] = append(copyWriteDict[gen],map[string]string{})
			arr := strings.Split(cw,"||")
			for _,item := range arr {
				kv_arr := strings.Split(item,"::")
				k,v := "default","-"
				if len(kv_arr) < 2 {
					v = strings.Trim(kv_arr[0]," ")
				}else{
					k = strings.Trim(kv_arr[0]," ")
					v = strings.Trim(kv_arr[1]," ")
				}
				copyWriteDict[gen][idx][k] = v
				log.Printf("[INFO] 文案模板: gender=%v,k=%v,v=%v",gen,k,v)
			}
		}
	}
	//[2017-7-25] other info
	for _,k := range sendFormat {
		if strings.Contains(output_str,k) {
			continue
		}
		otherFormat = append(otherFormat,k)
	}
	//[2017-6-8]Event log initializing
	err := eventlogclient.InitEventLogClient(&config.Conf.EventLogClient)
	if err != nil {
		log.Fatalf("[ERROR] eventlog.NewEventLogClient()初始化失败: %v", err)
	}
}

func Start() {
	// read msg info from file
	log.Printf("==========================")
	log.Printf("开始加载待发送用户文件: %v",*sendUserFile)
	//slog.Info("Start to load msg data : %v",*sendUserFile)
	readData(*sendUserFile,&userSet)
	//os.Exit(1)
	allNum := len(userSet) // total number
	if allNum == 0 {
		log.Printf("[INFO] 待发送用户数为空 :%v, 退出 ...", allNum)
		os.Exit(1)
	}
	log.Printf("[INFO] 一共有%v个待发送用户",allNum)
	rand.Seed(int64(time.Now().Nanosecond()))
	//Send msg for debuging (choose info from real user and replace number)
	log.Printf("[INFO] [%v]: 从用户集合中随机抽取数据发送给测试人员: %v ...",*mode,devSet)
	for _,v := range devSet {
		//User info : [phone,name,gender,group]
		randIdx := rand.Intn(allNum) // select user info randomly
		user := userSet[randIdx]
		//Find the opposite gender user
		randIdx1 := randIdx
		for idx, u := range userSet {
			if u["gender"] != user["gender"] {
				randIdx1 = idx
				break
			}
		}
		user1 := userSet[randIdx1]
		user["phone"] = v[0]
		user1["phone"] = v[0]
		//userSet[randIdx]["name"] = v[0]
		//user["gender"] = "male"
		//slog.Debug("copyWriteNum=%v,%v,%v,[v=%v],[user=%v]",copyWriteNum,user["gender"],len(copyWriteInfo[user["gender"]]),v,user)
		for i:=1;i<copyWriteNum;i++ {
			sendOne(user,copyWriteDict[user["gender"]][i][user["cwType"]])
			sendOne(user1,copyWriteDict[user1["gender"]][i][user1["cwType"]])
		}
		log.Printf("[%v]: 给测试人员(%v)分组(1->%v)分性别(male,female)发送短信 ...",*mode,v[1],copyWriteNum-1)
		//log.Printf("[%v]:Send msg to devUser (%v) from group 1 to group %v,both male and female ...",*mode,v[1],copyWriteNum-1)
	}
	log.Printf("[%v]: 测试人员发送完毕...",*mode)
	if *mode != "online" {
		log.Printf("非线上模式(mode=%v),退出 ...",*mode)
		os.Exit(0)
	}
	var wg sync.WaitGroup
	interval := pushTime / time.Duration(allNum)
	log.Printf("[INFO] 计算出来的发送时间间隔:interval=%v", interval)
	// ticker is used for rate control.
	ticker := time.Tick(interval)
	// send msgs to users.
	sendNum := 0
	// Connect to redis ro record users sended (sms_recall_male_done)
    f_normal, err := os.OpenFile(*doneUserFile, os.O_WRONLY|os.O_APPEND, 0666)
    if err != nil {
		log.Panic("[ERROR] 发送记录文件不存在: %v",doneUserFile)
		//slog.Err("Fail to open file %v",doneUserFile)
        //panic(err)
    }
    //f.WriteString("hello world\n")
    //f.WriteFile("hello world\n")
    defer f_normal.Close()
	//[2017-07-10]增加问题号码文件
    f_error, err := os.OpenFile(*errorUserFile, os.O_WRONLY|os.O_APPEND, 0666)
	if err != nil {
		log.Panic("[ERROR] 错误信息文件不存在:%v",*errorUserFile)
	}
	defer f_error.Close()
	log.Printf("==========================")
	log.Printf("[INFO] 开始正式发送...")
	cw_group := 0 //[2017-07-12]发送只分两组(0,1):发或不发
	for _, u := range userSet {
		cw_group = 0 //[2017-07-13] 7.12误发21.3w对照组用户(user_id%20=0),紧急修复
		idx, _ := strconv.Atoi(u["group"])
		if idx > 0 {
			cw_group = 1
		}
		//[user_id,phone,name,time,copyWriteName]
		realInfo := copyWriteDict[u["gender"]][cw_group][u["cwType"]]
		for _,v := range copyWriteInfo["var"] {
			realInfo = strings.Replace(realInfo,"{{"+v+"}}",u[v],-1)
		}
		//[2017-7-4] 修复写数据时用户重复、丢失的bug,最后还是80w里出现4个重复,go func 并发不能去掉,否则发送速度很慢
		wg.Add(1)
		go func() {
			defer wg.Done()
			cur_u := u //[2017-7-3]bug,多线程并发时，变量u没有单独复制,导致发送记录文件出现大量重复
			if cw_group == 0 {
				sendEvent(cur_u,"false")
				//log.Printf("[INFO] Event Server:对照组,写Kafka,发送(template:%v)给%v", copyWriteDict[cur_u["gender"]][cw_group][cur_u["cwType"]],cur_u["phone"])
			}else{
				sendEvent(cur_u,"true")
				provider,status = sendOne(cur_u,copyWriteDict[cur_u["gender"]][cw_group][cur_u["cwType"]])
				// user_id | dt | time | phone | net | provider | name | gender | cwname | cwcontent
				// user_id | time | phone | net | provider | name | group | gender | cwname | cwcontent //[2017-07-13]新版格式
				// date_time user_id name mobile_number gender operator provider groupid info_parameters cwname cwcontent [2017-7-25]
				// 其他冗余信息以json方式存储
				cur_info_map := map[string]string{}
				for _,k := range otherFormat{
					cur_info_map[k] = cur_u[k]
				}
				cur_info_str := "{}"
				cur_info_byte,err := json.Marshal(cur_info_map)
				if err != nil {
					log.Fatalf("[ERROR] json封装失败: %s", err.Error())
				}else{
					cur_info_str = string(cur_info_byte)
				}
				doneArray := []string{time.Now().Format("2006-01-02 15:04:05"),cur_u["user_id"],cur_u["name"],cur_u["phone"],cur_u["gender"],cur_u["net"],provider,cur_u["group"],cur_info_str,cur_u["cwType"],realInfo}
				//doneArray := []string{cur_u["user_id"],time.Now().Format("2006-01-02 15:04:05"),cur_u["phone"],cur_u["net"],provider,cur_u["name"],cur_u["group"],cur_u["gender"],cur_u["cwType"],realInfo}
				//doneArray := []string{cur_u["user_id"],time.Now().Format("2006-01-02"),time.Now().Format("15:04:05"),cur_u["phone"],cur_u["net"],provider,cur_u["name"],cur_u["gender"],copyWriteInfo["name"][0],realInfo}
				//[2017-07-10]近一周频繁出现发送途中失败的情形,程序要兼容非法号码(other+部分虚拟号码)造成的SMS Service报错(重试三次)
				if status == "success" {
					f_normal.WriteString(strings.Join(doneArray,"\t")+"\n")
				}else{//失败用户写入文件
					f_error.WriteString(strings.Join(doneArray,"\t")+"\n")
				}
			}
		}()
		<-ticker
		sendNum += 1
	}
	wg.Wait()
	log.Printf("[INFO] 所有%v用户发送完毕", sendNum)
	//Close event log as the end
	eventlogclient.Close()
}


func sendOne(user map[string]string, tpl string) (string,string) {
	//slog.Info("SMS Server : sending msg (template:%v) to %v", tpl,user)
	//mapping info
	//return "test_p","success" // [2017-07-13] 注释掉短信发送,追查问题
	curMap := map[string]string{}
	for _,v := range copyWriteInfo["var"] {
		curMap[v] = user[v]
	}
	//construct msg info
	scSms := service.Sms{
		CountryCode:  86,
		MobileNumber: user["phone"],
		FullText:  tpl,
		//FullText:  *tpl,
		Language:  "zh-CN",
		Type:      service.SmsTypeMarketing,
		Variables: curMap,
	}
	//[2017-07-11] james,SMS Server发送失败时,会继续用其他渠道商重试两次,累计三次后，返回错误信息,provider为空
	provider, err := sender.Send(&scSms)
	status := "success"
	if err != nil {
		log.Printf("[ERROR] 渠道商[%s]给[%v]发送[%v,%v]失败,跳过...SMS Service报错[%v]", provider,user["phone"],user["cwType"],tpl,err) //日志过多,暂时屏蔽
		//[2017-07-10]近一周频繁出现发送途中失败的情形,程序要兼容非法号码(other+部分虚拟号码)造成的SMS Service报错(重试三次)
		//log.Fatalf("[ERROR] (%s)发送失败: %s", user,err)
		status = "fail"
		provider = "-" //[2017-7-31]provider初始化(空值->-)
	}else{
		//log.Printf("[INFO] 渠道商[%s]给[%v]发送[%v,%v]", provider,user["phone"],user["cwType"],tpl) //日志过多,暂时屏蔽
	}
	return provider,status
}

func sendEvent(user map[string]string, group string) {
		data, err := json.Marshal(user)
		if err != nil {
			log.Fatalf("[ERROR] json封装失败: %s", err.Error())
			//slog.Err("Failed to  marshal user info : %s", err.Error())
			return
		}
		//log.Printf("[INFO] 发送Kafka:[%v]", provider,data) //日志过多,暂时屏蔽
		event, err := eventlog.NewEvent()
		if err != nil {
			log.Fatalf("[ERROR] eventlog初始化失败: %s", err.Error())
			//slog.Err("Failed to init eventlog : %s", err.Error())
			return
		}
		user_id, err := strconv.Atoi(user["user_id"])
		if err != nil {
			log.Fatalf("[ERROR] 用户id(%s)非整型!", err.Error())
			return
		}
		actor := eventlog.ActorReceiver{
			User : &eventlog.UserData{
				ID : user["user_id"],
			},
			MobileNumber: &eventlog.MobileNumber{ // only account service and client tracking log, no core servivce
				CountryCode: 86,
				Number: user["phone"],
			},
		}
		//listenAddress := config.Conf.Core.ListenAddress
		//listenAddress := config.Conf.EventLogClient.Addresses
		listenAddress := config.Conf.EventLog.RpcServer.Address
		host, _ := os.Hostname()
		sourceID := fmt.Sprintf("%v%v", host, listenAddress)


		//[2017-7-17]修复interana失效问题,改eventName
		if group == "true" {
			event.Name = "idlesms.sent"
		}else{
			event.Name = "idlesms.control.added"
		}
		//event.Name = "idle.sms." + group
		event.Source.Type = "putong-idle-user-sms-push"
		event.Source.Id = sourceID
		event.Actor = actor
		event.Timestamp = time.Now().UTC().UnixNano() / int64(time.Millisecond)
		eventData := eventlog.EventLogRpcMessage{
			//Topic: kafkaTopic,
			Topic: eventlog.TopicEventLog,
			Event: event,
			ID: int64(user_id),
		}
		/*
		eventData := eventlog.RpcMessage{
			Topic: kafkaTopic,
			Data:  data,
			ID:    int64(user_id),
		}*/
		//content := json.Marshal(eventData)
		//err = eventlogclient.SendEvent(content)
		err = eventlogclient.SendEvent(&eventData)
		//json_str,_ := ffjson.Marshal(&eventData)
		//json_str1,_ := ffjson.Marshal(&event)
		//json_str := ffjson.Marshal(event)
		//slog.Info("JSON: %+v",string(json_str))
		//slog.Info("JSON: %+v",string(json_str1))
		//log.Printf("JSON: %+v",string(json_str))
		//log.Printf("JSON: %+v",string(json_str1))
		//err = eventlogclient.SendData(&eventData)
		if err != nil {
			log.Fatalf("[ERROR] Eventlog : 给[%v]发送[%v]失败: %s", string(data),err.Error())
			//slog.Err("Failed to send event info (%v) to kafka: %s", content,err.Error())
			return
		}
		//log.Printf("[INFO] Eventlog : 给[%v]发送[%v],数据:[%v],Event:%+v",user["phone"],user["cwType"],string(data), event) //日志过多,暂时屏蔽
}

