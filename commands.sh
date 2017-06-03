#!/bin/bash
read -r nick chan BOT_NICK msg 

target_chan="#robots"
#ignore='^(!|%|\+|m[aeiou]th|infoobot|remind me|zb )'
ignorenick="^(zb|icinga|jackson|notify|moustache|tonkon)"

#DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
#BOT_NICK="$(grep -P "BOT_NICK=.*" ${DIR}/bot.sh | cut -d '=' -f 2- | tr -d '"')"

function debug {
  echo "$@" 1>&2
}

function say { 
  echo "PRIVMSG $chan :$1" > ${BOT_NICK}.io
}

priv=1

if [ "$chan" = "$BOT_NICK" ] ; then chan="$nick";priv=0 ; fi

name="(number)?wang(bot)?"

run() {
  numbers=$(<<<"$1" tr -cd ' [:digit:]-')
  if <<<"$numbers" grep -q '[0-9]'; then
    WANG=$(<<<"$WANG" tr -cd '_[:alnum:]') # just in case
    output=$(bash -r wangs/${WANG}.sh $numbers)
    if [ "$output" ]; then say "$output ($numbers)"; fi
  fi
}

runCmd() {
  case "`<<<"$1" tr '[:upper:]' '[:lower:]'`" in
    ""|help) 
      say "Currenlty playing wang $WANG: $(cat wangs/$WANG.desc)"
      say "wang play [name]: Play wang [name] | If no [name], show currently playing wang" 
      say "wang list: List wangs" 
      say "wang try <name> [:] <numbers>: Play <numbers> in wang <name>" 
      say "Join me in #numberwang!"
      say "Say numbers, and if you figure out the rule for what is numberwang or not, message gryphon to be immortalized as the solver."
      ;;
    wang|play) 
      if [ ! "$2" ]; then say "Currently playing wang $WANG: $(cat wangs/$WANG.desc)"; else
        newwang=$(<<<"$2" tr -cd '_[:alnum:]' | tr '[:upper:]' '[:lower:]')
        if [ -f wangs/$newwang.sh ]; then say "Playing wang $newwang"; echo -n "WANG=$newwang"; else say "Wang $newwang not found"; fi 
      fi
      ;;
    list)
      for file in wangs/*.desc; do
        say "$(basename -s ".desc" $file): $(cat $file)"
      done
      ;;
    try)
      WANG=$(<<<"$2" tr -cd '_[:alnum:]' | tr '[:upper:]' '[:lower:]')
      shift 2
      run "$*"
      ;;
    restart) screen -r wangbot -X kill ;;
    *) say "$nick: Unrecognized command $cmd" ;;
  esac
}

if grep -qiP "^${name}_[a-zA-Z]" <<<"$msg"; then
  runCmd `cut -d '_' -f 2- <<<"$msg"`

elif grep -qiP "^!?${name}[:,]* " <<<"$msg"; then
  runCmd `cut -d ' ' -f 2- <<<"$msg"`

elif grep -qiP "^!?${name}" <<<"$msg"; then
  runCmd ""

elif grep -qiP -v "$ignorenick" <<<"$nick"; then
  if ! `<<<"$chan" grep -qi "robots"` || [ -z `<<<"$msg" tr -cd '[:alpha:]'` ]; then 
    run "$msg"
  fi
fi
