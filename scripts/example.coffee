# Description:
#   Example scripts for you to examine and try out.
#
# Notes:
#   They are commented out by default, because most of them are pretty silly and
#   wouldn't be useful and amusing enough for day to day huboting.
#   Uncomment the ones you want to try and experiment with.
#
#   These are from the scripting documentation: https://github.com/github/hubot/blob/master/docs/scripting.md


###
data protocol of atcoder
key:
  id        abc000_a
  rivals    user_name
  ac_time   yyyy-mm-dd hh:mm:ss
  status    AC or WA

score: 100-200-300-500-600-1000
###
cron = require('cron').CronJob #cron package for timer job
jsondiffpatch = require("jsondiffpatch")
require('es6-promise').polyfill()

module.exports = (robot) ->

  ac = {}
  data = {}
  scores = {}
  promises = []
  users = ['jojojoe77','kmmech','mitar','nomnom_mst']

  robot.hear /badger/i, (res) ->
    res.send "Badgers? BADGERS? WE DON'T NEED NO STINKIN BADGERS"

  robot.hear /!list/i, (res) ->
    for u in users
      res.send u+" solved "+ac[u]+" problems and total score is "+scores[u]

  send = (chan,msg)->
    robot.send {room: chan}, msg

  get_data = (user)->
    return new Promise (resolve, reject) ->
      cnt = 0
      robot.http('http://kenkoooo.com/atcoder-api/problems?user='+user)
      .get() (err,res,body)->
        try
          data = JSON.parse body
          data[user] = data
          score = 0
          i =0
          for d in data
            # send '#test_jotaro',user+' '+d['ac_time']
            str = d['id']
            if str.slice(0,3)=='arc'
              str = str.slice(-1)
              if str == 'a' || str == '1'
                score += 300
              else if str == 'b' || str == '2'
                score += 500
              else if str == 'c' || str == '3'
                score += 600
              else if str == 'd' || str == '4'
                score += 1000
            else
              str = str.slice(-1)
              if str == 'a' || str == '1'
                score += 100
              else if str == 'b' || str == '2'
                score += 200
              else if str == 'c' || str == '3'
                score += 300
              else if str == 'd' || str == '4'
                score += 500
          # send '#test_jotaro',score
          data.sort (a,b) ->
            return a['ac_time'] < b['ac_time'] ? 1 : 0
          # send '#test_jotaro',data 
          scores[user]=score
          resolve
            data: data
            score: score
        catch error
          res.send "Ran into json parsing error :("
          reject err
          return
    .catch (error) ->
      send "",error

  chk_num_ac = (user) ->
    return new Promise (resolve, reject) ->
      cnt = 0;
      get_data(user)
        .then (value) ->
          for d in value.data
            if d['status'] == "AC"
              cnt = cnt + 1
          resolve
            cnt: cnt
            user: user
        .catch (error) ->
          send '#test_jotaro','we got something bad'
          send '#test_jotaro',error


  for u in users
    p = chk_num_ac(u)
    promises.push(p)

  Promise.all(promises)
    .then (values) ->
      for v in values
        # send '#test_jotaro',v['user']+" is "+v['cnt']
        ac[v['user']] = v['cnt']
      begin_pooling (users)
    .catch (error) ->
      console.log error

  begin_pooling = (users) ->
    new cron('* * * * * *', () ->
      promises = []
      for u in users
        p = chk_ac_diff(u)
        promises.push(p)
    ).start()


  chk_ac_diff = (user) ->
    return new Promise (resolve, reject) ->
      chk_num_ac(user)
        .then (value)->
          # send '#test_jotaro',user+' '+value.cnt+' '+ac[user]
          # ac['jojojoe77'] = 0
          if value.cnt > ac[user]
            #get new data and say something
            get_data(user)
              .then (value_data) ->
                data = value_data.data
                minDate = new Date("2000-01-01 00:00:00")
                solved_data=0
                for d in data
                  # send '',user+' '+d['ac_time'] + " " + d['id']
                  if new Date(d['ac_time']) > minDate
                    minDate = new Date(d['ac_time'])
                    solved_data = d
                # send '',"SOLVED "+solved_data['id']

                score=0
                str = solved_data['id']
                # str = str.slice(-1)
                if str.slice(0,3)=='arc'
                  str = str.slice(-1)
                  if str == 'a' || str == '1'
                    score += 300
                  else if str == 'b' || str == '2'
                    score += 500
                  else if str == 'c' || str == '3'
                    score += 600
                  else if str == 'd' || str == '4'
                    score += 1000
                else
                  str = str.slice(-1)
                  if str == 'a' || str == '1'
                    score += 100
                  else if str == 'b' || str == '2'
                    score += 200
                  else if str == 'c' || str == '3'
                    score += 300
                  else if str == 'd' || str == '4'
                    score += 500
                str = value_data.data[0]['id']
                send '#01_code_competition',"_*Accepted!*_ : " +user+" has just solved the _*"+score+"-point*_ problem *" + solved_data['id'] + "* and current total score is _*" +value_data.score+"*_"
                ac[user] = value.cnt
                data[user] = value_data.data
              .catch (error) ->
                send '#test_jotaro','ive got somthing bad right here'
                send '#test_jotaro',error
          resolve done:true
        .catch (error) ->
          send '#test_jotaro','oh oh'
          reject error


  # new cron( '* * * * * *', () =>
  #   fetch_information "test"
  # ).start()

  # _chk_num_ac('jojojoe77')
  #   .then(_chk_num_ac('kmmech'))
  #   .then(_chk_num_ac('hamko'))
  #   .then(watch_task())

  # myPromise = new Promise (resolve,reject) ->
  #   for u in users
  #     fetch_initial_state(u)
  #   success = true
  #   if success
  #     resolve 'stuff worked'
  #   else
  #     reject Error 'it broke'

  # myPromise.then() ->
  #   console.log "hello"


  # new cron( '* * * * * *', () =>
  #   fetch_information "test"
  # ).start()
  #
  # robot.respond /open the (.*) doors/i, (res) ->
  #   doorType = res.match[1]
  #   if doorType is "pod bay"
  #     res.reply "I'm afraid I can't let you do that."
  #   else
  #     res.reply "Opening #{doorType} doors"
  #
  # robot.hear /I like pie/i, (res) ->
  #   res.emote "makes a freshly baked pie"
  #
  # lulz = ['lol', 'rofl', 'lmao']
  #
  # robot.respond /lulz/i, (res) ->
  #   res.send res.random lulz
  #
  # robot.topic (res) ->
  #   res.send "#{res.message.text}? That's a Paddlin'"
  #
  #
  # enterReplies = ['Hi', 'Target Acquired', 'Firing', 'Hello friend.', 'Gotcha', 'I see you']
  # leaveReplies = ['Are you still there?', 'Target lost', 'Searching']
  #
  # robot.enter (res) ->
  #   res.send res.random enterReplies
  # robot.leave (res) ->
  #   res.send res.random leaveReplies
  #
  # answer = process.env.HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING
  #
  # robot.respond /what is the answer to the ultimate question of life/, (res) ->
  #   unless answer?
  #     res.send "Missing HUBOT_ANSWER_TO_THE_ULTIMATE_QUESTION_OF_LIFE_THE_UNIVERSE_AND_EVERYTHING in environment: please set and try again"
  #     return
  #   res.send "#{answer}, but what is the question?"
  #
  # robot.respond /you are a little slow/, (res) ->
  #   setTimeout () ->
  #     res.send "Who you calling 'slow'?"
  #   , 60 * 1000
  #
  # annoyIntervalId = null
  #
  # robot.respond /annoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #     return
  #
  #   res.send "Hey, want to hear the most annoying sound in the world?"
  #   annoyIntervalId = setInterval () ->
  #     res.send "AAAAAAAAAAAEEEEEEEEEEEEEEEEEEEEEEEEIIIIIIIIHHHHHHHHHH"
  #   , 1000
  #
  # robot.respond /unannoy me/, (res) ->
  #   if annoyIntervalId
  #     res.send "GUYS, GUYS, GUYS!"
  #     clearInterval(annoyIntervalId)
  #     annoyIntervalId = null
  #   else
  #     res.send "Not annoying you right now, am I?"
  #
  #
  # robot.router.post '/hubot/chatsecrets/:room', (req, res) ->
  #   room   = req.params.room
  #   data   = JSON.parse req.body.payload
  #   secret = data.secret
  #
  #   robot.messageRoom room, "I have a secret: #{secret}"
  #
  #   res.send 'OK'
  #
  # robot.error (err, res) ->
  #   robot.logger.error "DOES NOT COMPUTE"
  #
  #   if res?
  #     res.reply "DOES NOT COMPUTE"
  #
  # robot.respond /have a soda/i, (res) ->
  #   # Get number of sodas had (coerced to a number).
  #   sodasHad = robot.brain.get('totalSodas') * 1 or 0
  #
  #   if sodasHad > 4
  #     res.reply "I'm too fizzy.."
  #
  #   else
  #     res.reply 'Sure!'
  #
  #     robot.brain.set 'totalSodas', sodasHad+1
  #
  # robot.respond /sleep it off/i, (res) ->
  #   robot.brain.set 'totalSodas', 0
  #   res.reply 'zzzzz'
