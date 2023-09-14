########################################################################
###  IP sending shell                                       ### 
### This is written in shell script so that                          ###
### it always runs even python or something crashes                  ###
### curl is needed for this script                                   ###
### This file will be made as cronjob, running in every X minutes    ###


databaseAddress="http://1.2.3.4:5000"
ipserver=""
hostnamestr=""
# the server address to learn our IP from
IPServer="${databaseAddress}/learnip"

check_if_sth_changed()
{   
    our_result=$1
    ## if file exists
    isInFile=$(cat ./summaryIPs.txt | grep -c "$our_result")
    if [ $isInFile != 0 ]; then
         #string inside the file
	 echo "EXITING"
	 exit
    fi
    # if the file does not exist we can continue to send the entry to database
    
}


#learn hostname/name of the device
hostnamestr=$(hostname)

# learn internet outbound IP of the device
# We are also learning our IP from the database server
command_request="curl ${IPServer}" 
ipaddress=$(eval $command_request)

sum=""
summaryIPs=""    
# if ipaddress string is an IP address 
# if there is no error
if [[ $ipaddress != *"Could not resolve host"* ]]; then
    
    datenow=$(date "+%m/%d/%Y %H:%M:%S")    
    sum+="<date>${datenow}</date>\n"
    
    myssid=$(iwgetid -r)
    if [ -z "$myssid" ]; then
	sleep 2s
        $myssid=$(iwgetid -r)	
	if [ -z "$myssid" ]; then
	    echo "WIFI name is empty"
	    if [ -e summaryIPs.txt ];then
	        rm ./summaryIPs.txt
	    fi
	    if [ -e ifresult.txt ];then
	        rm ./ifresult.txt
	    fi
            # we will delete last records so that we will send next time
	    exit
	fi
    fi
    
    sum+="<wifiname>${myssid}</wifiname>\n"
    summaryIPs+="${myssid}"
    
    
    
    sum+="<internetIP>${ipaddress}</internetIP>\n<ifconfig>\n"
    summaryIPs+=" ${ipaddress}"
    
    
    readarray -t lines < <(ifconfig)
    count=0
    prevclass=""
    wirelessaddress=""
    macaddress=""
    summaryjson="{"
    for line in "${lines[@]}"; do
        if [[ "$line" == *": flags="* ]]; then
           internetCategory="${line%%:*}"
	    if [[ $count == 0 ]]; then
	        # the first line
	        sum+="<${internetCategory}>\n\t<line>${line}</line>\n"

	    else     
	        sum+="</${prevclass}>\n<${internetCategory}>\n\t<line>${line}</line>\n"
	    fi
	    prevclass=$internetCategory
	elif [[ "$line" == *" inet "* ]]; then
	    tokens=( $line ) 
	    sum+="\t<IP>${line}</IP>\n\t<address>${tokens[1]}</address>\n"
	    summaryIPs+=" ${tokens[1]}"
	    summaryjson+="\"${prevclass}\":\"${tokens[1]}\","
	    if [[ "$prevclass" == *"wl"* ]]; then
	         # we found the wireless IP address
		wirelessaddress="${tokens[1]}"	 
            fi
	elif [[ "$line" == *" ether "* ]]; then
	    tokens=( $line ) 
	    if [[ "$prevclass" == *"wl"* ]]; then
	         # we found the wireless mac address
		macaddress="${tokens[1]}"	 
            fi

	    # tokenize based on spaces
	    summaryjson+="\"${prevclass}\":\"${tokens[1]}\","
	    
	elif [[ "$line" != "" ]]; then
	    sum+="\t<line>${line}</line>\n"
	fi
        (( count++ ))
    done
    
    summaryjson+="}"
   
    sum+="</${prevclass}>\n</ifconfig>"
    
    if [[ "$count" -eq  0 ]]; then
        echo "ifconfig is empty"
        exit  
    fi
    
    #summaryIP is ready now. We can check if something is changed
    check_if_sth_changed "\"${summaryIPs}\""
    #if there is a change the code will continue else, it will exit here
    
    # we should continue as the previous ifconfig is not same    
    #command_request="curl -X POST -d @ifresult.txt -H \"Content-Type: application/json\" ${databaseAddress}/set/IPDEVICE_${hostnamestr}" 
    #command_request="curl -X POST -d \"${sum}\" -H \"Content-Type: application/json\" ${databaseAddress}/set/IPDEVICE_${hostnamestr}" 
    command_request="curl -X POST -d \"${wirelessaddress}\" -H \"Content-Type: application/json\" ${databaseAddress}/set/IP_vcu@${macaddress}"
       
    commandoutput=$(eval $command_request)
    
    if [[ $commandoutput == "{\"message\":\"ADDED\"}" ]]; then
       # write IP address to text file, meaning we have successfully sent our IP to server.
       # this file is the evidence that we sent successfully. ifresult.txt iss the evidence that we parsed ifconfig file
       echo -e $summaryIPs > summaryIPs.txt
       #overwrites the file
       echo -e $sum > ifresult.txt
    fi
        
else
    # can not access internet
    # remove the previous IP address record
    if [ -e summaryIPs.txt ];then
        rm ./summaryIPs.txt
    fi
    
fi
