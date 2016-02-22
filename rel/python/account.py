#!/usr/bin/python
# coding:utf-8

import os
import json
#from json import *

g_dictUid = {}
g_dictAction = {}
g_dictResult = []


def analyseLog(dirName, filePre):
    vDate = filePre
    # fileName = dirName + '\\' + filePre + '.log'
    fileName = dirName + '/' + filePre + '.log'
    logFile = open(fileName)
    for eachLine in logFile:
        eachLine = eachLine.strip('\r\n')
        uid = None
        action = None
        start = eachLine.find('uid=')
        end = eachLine.find(',')
        index = eachLine.find('action')
        if start > 0 and end > 0 and index > 0:
            uid = eachLine[start+4:end]
            action = eachLine[index+7:]
            # print "uid:", uid, "action:", action
            if action == '-1':
                action = 'download'
            elif action == '0':
                action = 'register'
            elif action == '2':
                action = 'login'
            elif action == '4':
                action = 'verify'
            else:
                action = 'undefine'

        if uid is not None and action is not None:
            if vDate not in g_dictUid:
                g_dictUid[vDate] = []

            uidList = g_dictUid[vDate]
            if uid not in uidList:
                uidList.append(uid)

            if vDate not in g_dictAction:
                g_dictAction[vDate] = {}

            actionDict = g_dictAction[vDate]
            # if action not in actionDict:
            #     actionDict[action] = 0
            if 'download' not in actionDict:
                actionDict['download'] = 0
            if 'register' not in actionDict:
                actionDict['register'] = 0
            if 'login' not in actionDict:
                actionDict['login'] = 0
            if 'verify' not in actionDict:
                actionDict['verify'] = 0

            actionDict[action] += 1

            actionDict['pcu'] = len(uidList)
            actionDict['date'] = vDate

    logFile.close()


def transData():
    for key in g_dictAction:
        entry = {}
        entry['date'] = key
        entry['value'] = g_dictAction[key]
        g_dictResult.append(entry)


def saveData():

    # print g_dictUid
    # print "==========================================="
    # print g_dictAction
    # print "==========================================="
    # print g_dictResult
    sortedDict = [(k, g_dictAction[k]) for k in sorted(g_dictAction.keys())]

    # print "==========================================="
    # print sortedDict
    #jsonData = JSONEncoder().encode(g_dictDate)
    #jsonData1 = json.dumps(g_dictResult)
    # jsonData1 = json.dumps(g_dictAction, sort_keys=True)
    # print type(jsonData1)
    # print jsonData1

    with open("result.json", 'w') as f:
        for x in sortedDict:
            x = str(x) + '\n'
            x = x.replace('\'', '"')
            f.write(x)


def accountLog(dirPath):
    #i = 0
    for root, dirs, files in os.walk(dirPath):
        # print root, dirs, files
        for fname in files:
            index1 = fname.find('.log')
            index2 = fname.find('-')
            if index1 > 0 and index2 > 0:
                # print index, fname[:index]
                # accountLog(fname[:index])

                analyseLog(root, fname[:index1])
                # print "Account " + fname + " OK!"
                # i += 1
                # if i > 10:
                #     return


def main():
    # accountLog("F:\project\php\starword\logs")
    accountLog("/home/sw/Project/PHP/starword/logs")
    transData()
    saveData()


if __name__ == '__main__':
    main()
    print "Game Over!"
