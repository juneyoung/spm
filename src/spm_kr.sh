#!/usr/bin/env bash

# Use this in Linux system #!/bin/env bash #!bin/bash
# @Params $1 command 
# @Params $2 Spring boot active profile
# @Params $3 Spring boot war file location includes extension

COLOR_NC='\e[0m' # No Color
COLOR_WHITE='\e[1;37m'
COLOR_BLACK='\e[0;30m'
COLOR_BLUE='\e[0;34m'
COLOR_LIGHT_BLUE='\e[1;34m'
COLOR_GREEN='\e[0;32m'
COLOR_LIGHT_GREEN='\e[1;32m'
COLOR_CYAN='\e[0;36m'
COLOR_LIGHT_CYAN='\e[1;36m'
COLOR_RED='\e[0;31m'
COLOR_LIGHT_RED='\e[1;31m'
COLOR_PURPLE='\e[0;35m'
COLOR_LIGHT_PURPLE='\e[1;35m'
COLOR_BROWN='\e[0;33m'
COLOR_YELLOW='\e[1;33m'
COLOR_GRAY='\e[0;30m'
COLOR_LIGHT_GRAY='\e[0;37m'

export USE_COLOR=0

# In case of Linux, Change /Users to /home
CONFIG_PATH="/Users/${USER}/etc/spm/config"
DATA_PATH="/Users/${USER}/etc/spm/data"
LOG_PATH="/Users/${USER}/etc/spm/logs"
VERSION="0.01a"

if [ $( uname ) = 'Linux' ]; then
	echo '콘솔 색상을 지원합니다.'
	USE_COLOR=1
else 
	echo '콘솔 색상을 지원하지 않습니다.'
fi;

echo "SPM(스프링부트 프로세스 매니저) v.${VERSION} 작성일 2019.06.01";


# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [S] Define UI Utility functions =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====


function printTable() {
    local -r delimiter="${1}"
    local dataText=$( cat "$2" );
    local -r data="$(removeEmptyLines "${dataText}")"

    if [[ "${delimiter}" != '' && "$(isEmptyString "${data}")" = 'false' ]]
    then
        local -r numberOfLines="$(wc -l <<< "${data}")"

        if [[ "${numberOfLines}" -gt '0' ]]
        then
            local table=''
            local i=1

            for ((i = 1; i <= "${numberOfLines}"; i = i + 1))
            do
                local line=''
                line="$(sed "${i}q;d" <<< "${data}")"

                local numberOfColumns='0'
                numberOfColumns="$(awk -F "${delimiter}" '{print NF}' <<< "${line}")"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi

                # Add Header Or Body

                table="${table}\n"

                local j=1

                for ((j = 1; j <= "${numberOfColumns}"; j = j + 1))
                do
                    table="${table}$(printf '#| %s' "$(cut -d "${delimiter}" -f "${j}" <<< "${line}")")"
                done

                table="${table}#|\n"

                # Add Line Delimiter

                if [[ "${i}" -eq '1' ]] || [[ "${numberOfLines}" -gt '1' && "${i}" -eq "${numberOfLines}" ]]
                then
                    table="${table}$(printf '%s#+' "$(repeatString '#+' "${numberOfColumns}")")"
                fi
            done

            if [[ "$(isEmptyString "${table}")" = 'false' ]]
            then
                echo -e "${table}" | column -s '#' -t | awk '/^\+/{gsub(" ", "-", $0)}1'
            fi
        fi
    fi
}

function removeEmptyLines() {
    local -r content="${1}"
    echo -e "${content}" | sed '/^\s*$/d'
}

function repeatString() {
    local -r string="${1}"
    local -r numberToRepeat="${2}"
    if [[ "${string}" != '' && "${numberToRepeat}" =~ ^[1-9][0-9]*$ ]]
    then
        local -r result="$(printf "%${numberToRepeat}s")"
        echo -e "${result// /${string}}"
    fi
}

function isEmptyString() {
    local -r string="${1}"
    if [[ "$(trimString "${string}")" = '' ]]
    then
        echo 'true' && return 0
    fi
    echo 'false' && return 1
}

function trimString() {
    local -r string="${1}"
    sed 's,^[[:blank:]]*,,' <<< "${string}" | sed 's,[[:blank:]]*$,,'
} 


function printConsole {
	if [ "$USE_COLOR" -eq 1 ]; then
		echo -e '\e[1;32m' "[ SPM ]" '\e[0m' "$1"
	else 
		echo "[ SPM ] $1"
	fi;
}


function printError {
	if [ "$USE_COLOR" -eq 1 ]; then
		echo -e '\e[1;31m' "[ SPM ]" '\e[0m' "$1"
	else 
		echo "[ SPM ] $1"
	fi;
}

# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [E] Define UI Utility functions ===== 
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====


# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [S]  Define Internal Functions =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====

function resetDataFile {
	##### Do not additional echo in this function 
	echo "profile=pid=start_date" > "$DATA_PATH/temp.data";
}

# @Params $1 profile
# @Params $2 pid
function storeProcess {

	if [ ! -d "$DATA_PATH" ]; then
		printConsole "부트 프로파일 $1 에 대한 데이터 디렉토리가 존재하지 않습니다. 디렉토리를 생성합니다.";
		mkdir -p "$DATA_PATH";
	fi;

	if [ ! -f "$DATA_PATH/temp.data" ]; then
		resetDataFile
	fi;

	local current=$( date '+%Y-%m-%d %H:%M:%S' )
	echo "$1=$2=$current;" >> "$DATA_PATH/temp.data";	# echo contains carriage return itself
}

function grepPid {
	##### Do not additional echo in this function 
	foundPid=$( ps -ef | grep "active=$1" | awk '{print $2}' | sed -n 1p )
	echo "$foundPid";
}

function readPidFromData {
	##### Do not additional echo in this function 
	local line=$( cat "$DATA_PATH/temp.data" | grep "^$1=" );
	if [ ! -n "$line" ]; then
		echo "";
	else
		local found=$( echo "$line" | awk -F"=" '{print $2}' );
		echo "$found";
	fi;
}

function start {
	printConsole "부트 프로파일 [ $1 ] 에 대한 웹서비스를 기동합니다."
	if [ ! -n "$1" ]; then
		printError "실행할 프로파일 변수가 전달되지 않았습니다.";
		exit 1;
	else
		if [ ! -n "$2" ]; then
			printError "실행할 bootWar 파일 경로가 제공되지 않았습니다.";
			exit 1;
		fi;

		if [ ! -f "$2" ]; then
			printError "파일 경로 [ $2 ] 가 올바르지 않습니다.";
			exit 1;
		fi;

		# Validation for duplicated profile
		local reqProfile=$( readPidFromData "$1" )
		if [ -n "$reqProfile" ]; then
			printConsole "부트 프로파일 [ $1 ] 이 이미 기동 중입니다. 요청을 무시합니다.";
			exit 1;
		else 
			printConsole "부트 프로파일 [ $1 ] 에 대한 준비가 완료되었습니다."
		fi;

		printConsole "부트 웹서비스를 [ $1 ] 프로파일로 실행합니다. 파일경로 : [ $2 ]";
		# Check log location 
		if [ ! -d "$LOG_PATH/$1" ]; then
			printConsole "부트 프로파일 [ $1 ] 에 대한 로그 디렉토리가 존재하지 않습니다. 디렉토리를 생성합니다.";
			mkdir -p "$LOG_PATH/$1"
		fi; 
		# echo "Execution command is [ java -Dspring.profiles.active=$1 -jar $2 > $LOG_PATH/$1/out.log & ]";
		nohup java -Dspring.profiles.active="$1" -jar "$2" > "$LOG_PATH/$1/out.log" &
		processId=$( grepPid "$1" );
		printConsole "부트 프로세스가 성공적으로 기동되었습니다. 프로세스 아이디는 [ $processId ] 입니다.";
		storeProcess "$1" "$processId"
	fi;
}

function stop {
	printConsole "부트 프로파일 [ $1 ] 에 대한 서비스를 중지합니다."
	local processToKill=$( readPidFromData "$1" );
	kill "$processToKill"
	# After delete, remove the corresponding line from data file
	# sed is not good for compartibility. Use awk instead
	# remove a line which starts with "$profile="
	if [ "$?" -eq 0 ]; then
		# echo "execute remove line from file command [ awk '!/^$1=/' $DATA_PATH/temp.data > $DATA_PATH/temp.temp"
		local pattern="^$1="
		# echo "Find a line which starts with [ $pattern ]"
		# awk '!/$pattern/' "$DATA_PATH"/temp.data > "$DATA_PATH"/temp.temp # ???!!!!
		awk '/$pattern/' "$DATA_PATH/temp.data" > "$DATA_PATH/temp.temp" 
		resetDataFile
		cat "$DATA_PATH/temp.temp" >> "$DATA_PATH/temp.data";
	else 
		printError "부트 프로파일 [ $1 ] 에 대한 중지를 실패하였습니다. 프로그램을 종료합니다.";
		exit 1;
	fi;
}	

function list {
	printConsole "데이터 기반으로 관리되는 프로세스를 나열합니다. 데이터 디렉토리 : [ $DATA_PATH ]"
	if [ ! -f "$DATA_PATH/temp.data" ]; then
		touch "$DATA_PATH/temp.data";
		resetDataFile
	fi;
	printTable "=" "$DATA_PATH/temp.data";
}

function tailLogs {
	tail -f "$LOG_PATH/$1/out.log";
}

function resetData {
	rm "$DATA_PATH"/*
	resetDataFile
}


# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [E]  Define Internal Functions =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====




# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [S] Checking required paths
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====

if [ -d "$CONFIG_PATH" ]; then
	printConsole "필수 설정 디렉토리 OK : [ $CONFIG_PATH ].";
else
	mkdir -p "$CONFIG_PATH";
fi;

if [ -d "$DATA_PATH" ]; then
	printConsole "필수 데이터 디렉토리 OK : [ $DATA_PATH ].";
else
	mkdir -p "$DATA_PATH";
fi;

if [ -d "$LOG_PATH" ]; then
	printConsole "필수 로그 디렉토리 OK : [ $LOG_PATH ].";
else
	mkdir -p "$LOG_PATH";
fi;

# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [E] Checking required paths
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====



if [ "$#" -lt 1 ]; then
	echo "인수가 부족합니다. 실행하기 위해서 [command] [Spring.profile] 를 추가하십시오.";
	echo "명령어 목록";
	echo "  start	[profile] : 전달된 프로파일로 웹서비스를 기동합니다.";
	echo "  stop [profile] : 전달된 프로파일로 기동 중인 웹서비스를 중지합니다.";
	echo "  restart [profile] : 전달된 프로파일로 기동 중이 웹서비스를 재시작합니다.(작업중)";
	echo "  logs [profile] : 전달된 프로파일에 해당하는 웹서비스의 로그를 출력합니다.";
	echo "  list : 관리하고 있는 프로세스 목록을 출력합니다.";
	exit 0;
else
	case "$1" in
		start)
			start "$2" "$3";
			printTable "=" "$DATA_PATH/temp.data"
			;;
		stop)
			stop "$2";
			printTable "=" "$DATA_PATH/temp.data"
			;;
		restart)
			stop "$2";
			start "$2";
			;;
		list)
			list; 
			;;
		logs)
			tailLogs "$2";
			;;
		resetData)
			resetData;
			;;
	esac
fi;

exit 0;
