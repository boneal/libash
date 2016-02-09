############################################################################
#The log function can be instantiated and easily used                      #
#for any given child script by invoking something like                     #
#function coreLog()                                                        #
# {                                                                        #
#   log "$logOpts" $logLevel "$logDir" "$logFile" $1 "$2" "$3" $4          #
# }                                                                        #
#And then calling it like                                                  #
#coreLog 5 "Message" "Source" #OfBlankLinesBefore #OfBlankLinesAfter       #
#coreLog 5 "Starting Fix Slave for socket $sock" "$callerScriptName.init"  #
#coreLog 5 "The script started with the $output"                           #
#                                                                          #
#This produces very easy to read logs and an easy way to                   #
#controle your level of logging                                            #
#logOpts    => Options include                                             #
#               f - Log to file                                            #
#               e - Log to standard out                                    #
#               s - Log to syslog                                          #
#WARNNING: DO NOT ENABLE e FOR ECHO IF YOU RETURN VARIABLES                #
#          FROM FUNCTIONS!!!                                               #
#logLevel   => Numeric value from 0 to 5                                   #
#               0 = Fatal - See below for more detail                      #
#Author: Bryan O'Neal                                                      #
#License: APL                                                              #
############################################################################
function log()
{
	unset tag
	unset sepNumPre
	unset sepNumPost
	local logMode=$1
	local appLogLevel=$2
	local logDir="$3"
	local logFile="$4"
	local messageLogLevel="$5"
	local message="$6"
	local tag="$7"
	local sepNumPre=$8
	local sepNumPost=$9
	local LogLevelTAG
	local messageLength
	local messageTemp
	local messageLine
	local tagSync
	local myPid

	tagSync=1

	unset LogLevelTAG messageLength messageTemp messageLine
	if [[ $messageLogLevel -le $appLogLevel ]]; then
		#Should I include $SHLVL if the level is more then 2?
		if [[ $$ -eq $BASHPID  ]]; then
			myPid=$$
		else
			myPid="$$ |- $BASHPID"
			#note -> is interpreted and produces /proc/{$BASHPID+1}: No such file or directory errors
		fi
		case "$messageLogLevel" in
		0) LogLevelTAG="[FATAL]"
				#If you can capture anything before you die in the woods - this is the place to say it
				#This will even provide a bash version of a backtrace for deeply netsted functions
				;;
		1) LogLevelTAG="[CRITICAL ERROR] PID:$myPid"
				#Something occurred that, generally speaking, should not have occurred
				;;
		2) LogLevelTAG="[WARN]   PID:$myPid"
				#Something may not be right here. Better check it out
				;;
		3) LogLevelTAG="[INFO]   PID:$myPid"
				#Hey man - I am like doing that thing you asked
				;;
		4) LogLevelTAG="[DEBUG]  PID:$myPid"
				#Hey! Hey! Hey - I totally just did that thing that leads to the thing that helps me do the thing you asked!
				;;
		5) LogLevelTAG="[TRACE]  PID:$myPid"
				#If you feel you need a tweeker to tell you about every position of every match stick he/she
				#just laid next to every other match stick on the table, then this may be the log level for you.
				#This is for when you want to see how they script is progressing and do some incredibly detailed debugging
				#But this level of detail would be annoying most of the time. Even if you are trying to debug something
				#This also includes the pid of the process.
				;;
		esac

		if [[ ! "${logDir: -1}" == "/" ]]; then
			logDir="${logDir}/"
		fi
		if [[ ! -d $logDir ]]; then
				mkdir -p ${logDir}
		fi
		if [[ ! -f $logDir$logFile ]]; then
				touch ${logDir}${logFile}
		fi
		if [[ ! -w ${logDir}${logFile} ]]; then
			return 1
		fi
		if [[ $messageLogLevel -le 1 ]]; then
			logMode=$( echo $logMode s )
		fi
		if [[ $messageLogLevel == 0 ]]; then
			logMode=$( echo $logMode t )
		fi

		if [[ $logMode =~ "t" ]]; then
			#Triggerd on log level 0
			messageTemp="$(pstree -p $$)"
			local frame
			local bashTrace
			frame=0
			messageTemp=$(echo -e "${messageTemp}\n$*" 2>&1)
			messageTemp=$(echo "${messageTemp}\nThe folowing trace is in the format of")
			messageTemp=$(echo "${messageTemp}\nLine Fucntion Script" )
			bashTrace=$(while caller $frame; do ((frame++)); done)
			message=$(echo -e "${message}\n${messageTemp}\n${bashTrace}")
			unset messageTemp
			unset bashTrace
		fi	
		#This block indents multi line message blocks. Yes that is a tab and a space
		messageLength=$(echo -e "$message" | wc -l)
		if [[ $messageLength -gt 1 && $logMode =~ "f" ]]; then
			##################################################
			# Prep message format so \n and other newlines are
			# utilized for formatting without causing issues with
			# raw multi line out put that may contain control 
			# characters that we do not want interpreted
			##################################################
			if [[ $(echo "$message" | wc -l) -lt 2 ]]; then
				#Without -e the above will be one line when people use \n intentionally 
				message=$(echo -e "$message" )
			fi
			while read -r messageLine; do
				if [[ -z $messageTemp ]]; then
					messageTemp=$(echo -e "${messageLine}" )
				else
					messageTemp=$(echo -e "${messageTemp}\n\t ${messageLine}" )
				fi
			done <<< "$message"
			message="$messageTemp"
			unset messageTemp
		fi
		if [[ -n $sepNumPre ]]; then
			nl=0
			while [[ $nl -le $sepNumPre ]]; do
				if [[ $logMode =~ "e" ]]; then
					echo >&2
				fi
				if [[ $logMode =~ "f" ]]; then
					echo >> ${logDir}${logFile}
					let nl="$nl + 1"
				fi
			done
		fi
		#This cleans up the initial indent on multi line messages 
		#and creates the indent for single line messages
		message="\t $message"
		if [[ -n $tag ]]; then
			#if [[ $logMode =~ "e" ]]; then
			#       if [[ -n $tag ]]; then
			#               echo -e "$LogLevelTAG\t $(date) \t $tag"
			#       fi
			#fi
			if [[ $logMode =~ "f" ]]; then
				if [[ $tagSync -eq 1 ]]; then
					#When you are loging lots of processes to one file this keeps things orderly
					message=$(echo -e "$LogLevelTAG\t $(date) \t $tag \n${message}")
				else
					echo -e "$LogLevelTAG\t $(date) \t $tag" >> ${logDir}${logFile}
				fi

			fi
		fi
		if [[ $logMode =~ "e" ]]; then
			echo -e $message >&2
		fi
		if [[ $logMode =~ "f" ]]; then
			echo -e "$message" >> ${logDir}${logFile}
		fi
		if [[ $logMode =~ "s" ]]; then
			logger "$0  $LogLevelTAG   $message"
			#could use -p facility.level like
			#logger -p local3.info  "     $message"
		fi
	
		if [[ ! -z $sepNumPost ]]; then
			nl=0
			while [[ $nl -le $sepNumPost ]]; do
				if [[ $logMode =~ "e" ]]; then
					echo >&2
				fi
				if [[ $logMode =~ "f" ]]; then
					echo >> ${logDir}${logFile}
					let nl="$nl + 1"
				fi
			done
		fi
	fi
}
