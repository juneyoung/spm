#!/usr/bin/env bash

# Use this in Linux system #!/usr/bin/env bash #!bin/bash
# @Params $1 command 
# @Params $2 Spring boot active profile
# @Params $3 Spring boot war file location includes extension


CONFIG_PATH="/Users/${USER}/etc/spm/config"
DATA_PATH="/Users/${USER}/etc/spm/data"
LOG_PATH="/Users/${USER}/etc/spm/logs"
VERSION="0.01a"

echo "SPM(Spring Process Manager) v.${VERSION} writen 1st JUN 2019";

# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [S] Checking required paths
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====

if [ -d "$CONFIG_PATH" ]; then
	echo "Required config directory : [ $CONFIG_PATH ] exists. Good to go ...";
else
	mkdir -p "$CONFIG_PATH";
fi;

if [ -d "$DATA_PATH" ]; then
	echo "Required data directory : [ $DATA_PATH ] exists. Good to go ...";
else
	mkdir -p "$DATA_PATH";
fi;

if [ -d "$LOG_PATH" ]; then
	echo "Required logs directory : [ $LOG_PATH ] exists. Good to go ...";
else
	mkdir -p "$LOG_PATH";
fi;

# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [E] Checking required paths
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====


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

# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [E] Define UI Utility functions ===== 
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====


# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== [S]  Define UX Functions =====
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
		echo "Data directory for profile $1 does not found. Make one $DATA_PATH";
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
	echo "Start bootWar and retore data and logs with profile [ $1 ]"
	if [ ! -n "$1" ]; then
		echo "Need a profile to execute";
		exit 1;
	else
		if [ ! -n "$2" ]; then
			echo "Executable war file must provided";
			exit 1;
		fi;

		if [ ! -f "$2" ]; then
			echo "$2 is not a executable war file";
			exit 1;
		fi;

		# Validation for duplicated profile
		local reqProfile=$( readPidFromData "$1" )
		if [ -n "$reqProfile" ]; then
			echo "bootProcess [ $1 ] is already running ... $reqProfile";
			exit 1;
		else 
			echo "start new process with $reqProfile $1"
		fi;

		echo "Start [ $1 ] with file [ $2 ]";
		# Check log location 
		if [ ! -d "$LOG_PATH/$1" ]; then
			echo "Log directory for profile $1 does not found. Make one $LOG_PATH/$1";
			mkdir -p "$LOG_PATH/$1"
		fi; 
		# echo "Execution command is [ java -Dspring.profiles.active=$1 -jar $2 > $LOG_PATH/$1/out.log & ]";
		nohup java -Dspring.profiles.active="$1" -jar "$2" > "$LOG_PATH/$1/out.log" &
		processId=$( grepPid "$1" );
		echo "Spring process run with pid [ $processId ]";
		storeProcess "$1" "$processId"
	fi;
}

function stop {
	echo "Stop spring boot process with profile [ $1 ]"
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
		echo "Failed to stop boot process with profile $1";
		exit 1;
	fi;
}	

function list {
	echo "List up managed spring boot processes from data folder [ $DATA_PATH ]"
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
# ===== [E]  Define UX Functions =====
# ===== ===== ===== ===== ===== ===== ===== =====
# ===== ===== ===== ===== ===== ===== ===== =====



if [ "$#" -lt 1 ]; then
	echo "need argument [command] [Spring.profile] for execute ...";
	echo "command list";
	echo "  start	[profile] : Start bootWar with given profile";
	echo "  stop [profile] : Stop bootWar with given profile";
	echo "  restart [profile] : Retart bootWar with given profile";
	echo "  logs [profile] : Print out logs with given profile";
	echo "  list : show managed process list";
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