function print_package(){
	echo -e "\n"
	echo -e "+-------------------------------"
	echo -e "| ${1}"
	echo -e "+-------------------------------"
}

function print_task(){
	echo -e "\n"
	echo -e "#################################"
	echo -e "# ${1}"
	echo -e "#################################"
}


function verify_package() {
	local file=${1}
	local shasum=${2}

    SHA=$(shasum  -a 256 ${file} | head -n1 | awk '{print $1;}')
    [[ ${SHA} == ${shasum} ]]
    return
}

function download_package() {
	local name=${1}
	local file=${2}
	local url=${3}
	local shasum=${4}

	print_package "${name}"

	if [ -z ${shasum} ]; then 
		# no sha, so always download
		curl -SL -o ${file} ${url}

	else 
		# use sha to verify/download

		if [ ! -f ${file} ]; then
			echo " ${name} doesn't exist, download..."
			DOWNLOAD=1
		elif ! verify_package ${file} ${shasum} ; then
			echo " ${name} is NOT Valid, download..."
			DOWNLOAD=1
		fi

		if [ "$DOWNLOAD" = "1" ]; then
			echo " Downloading ${file}..."
			curl -SL -o ${file} ${url}
		fi

		if verify_package ${file} ${shasum}; then
			echo " ${name} is Valid"
		else 
			echo " ${name} is NOT Valid!"
			exit 1
		fi
	fi

	echo -e "\n"
}
