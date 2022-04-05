#!/bin/bash 

if [ "$1" = "" ] | [ "$2" = "" ] | [ "$3" = "" ] | [ "$4" = "" ]; then
    echo usage: get_user_projects.sh \<alm-url:port\> \<sa_username\> \<password\> \<user\> 
    echo example: get_user_projects.sh http://nimbusserver.aos.com:8082 admin Password1 sa 
    echo example: get_user_projects.sh http://nimbusserver.mfadvantageinc.com:8082 admin mfDemo\\\$20 alex_alm 
    exit 2
fi

cd /tmp

#Authenticate with ALM and save cookies
echo "Authenticating with ALM for API calls..."
response="$(curl -k --connect-timeout 5 --silent --show-error --cookie-jar headers_and_cookies -w %{http_code} -d "<alm-authentication><user>$2</user><password>$3</password></alm-authentication>" --header "Content-Type: application/xml" $1/qcbin/authentication-point/alm-authenticate)"

if [ $? != 0 ]; then
   ls -l headers_and_cookies
   rm -f headers_and_cookies
   exit $?
fi

response_code="$(echo $response | grep -E -o '.{3}$')"

if [ "$response_code" != "200" ]; then
    echo $response
    rm -f headers_and_cookies
    exit 1
fi

#Authenticating with ALM for SiteSession Cookie
echo "Authenticating with ALM for SiteSession Cookie"
response="$(curl -k --connect-timeout 5 --silent --show-error --cookie-jar headers_and_cookies --cookie headers_and_cookies -w %{http_code} -d "<session-parameters><client-type>REST client</client-type></session-parameters>" --header "Content-Type: application/xml" $1/qcbin/rest/site-session)"

if [ $? != 0 ]; then
   rm -f headers_and_cookies
   exit $?
fi

response_code="$(echo $response | grep -E -o '.{3}$')"

if [ "$response_code" != "201" ]; then
    rm -f headers_and_cookies
    exit 1
fi

XSRFTOKEN="$(cat headers_and_cookies | grep XSRF-TOKEN | sed 's/.*XSRF-TOKEN//' )"

#Get projects for user
echo "Getting projects for user: " $4
response="$(curl -k --connect-timeout 5 --silent --show-error -w %{http_code} --cookie headers_and_cookies -o $4_projects.json --header "Content-Type: application/json" --header "X-XSRF-TOKEN: $XSRFTOKEN" $1/qcbin/v2/sa/api/site-users/$4/projects )"

if [ $? != 0 ]
then
    echo "result: " $?
    rm -f headers_and_cookies
    exit $?
fi

response_code="$(echo $response | grep -E -o '.{3}$')"
if [ "$response_code" != "200" ] # 200 = success
then
    echo "response_code:" $response_code
    echo "response:" $response
    rm -f headers_and_cookies
    exit 1
fi

i=0

while ( true )
do
    project=$(jq -r ".projects.project[$i].name" /tmp/$4_projects.json)

    if [ $? != 0 ]
    then
	echo "Inside if"
	# If there's only one project, there's no array
    	project=$(jq -r ".projects.project.name" /tmp/$4_projects.json)

        echo $project
        echo "Number of projects: 1"
        exit $?
    fi

    if [ $project = null ]
    then
        echo "Number of projects: " $i
        exit $?
    fi

    echo $project

    i=`expr $i + 1`
done
