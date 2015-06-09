#! /bin/bash
timeout=15
declare ok_tmp
declare error_tmp
declare other_tmp

for ip in $(cat serverlist.txt); do
echo -n "."
ret=$(ssh -o BatchMode=yes -o StrictHostKeyChecking=no -o ConnectTimeout=${timeout} ${ip} echo "works" 2>&1)
    if [[ ${ret} == works ]]
        then
                ok_tmp+="$ip $host \t- OK\n"
    elif [[ $ret == "Permission denied"* ]]
        then
                error_tmp+="$ip $host $ret\n"
    else
                other_tmp+="$ip $host $ret\n"
    fi
done

echo -e "\nList of hosts with OK access"
echo -e $ok_tmp

echo "List of hosts with access problem"
echo -e $error_tmp

echo "List of hosts with other Problem"
echo -e $other_tmp
