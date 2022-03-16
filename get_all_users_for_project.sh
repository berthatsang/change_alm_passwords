#!/bin/bash 

if [ "$1" = "" ] | [ "$2" = "" ] | [ "$3" = "" ] | [ "$4" = "" ]; then
    echo usage: get_all_users_from_project.sh \<alm-url:port\> \<sa_username\> \<password\> \<project\> [\<domain\>]
    echo example: get_all_users_from_project.sh http://nimbusserver.aos.com:8082 admin Password1 ESIG [\<domain\>]
    echo example: get_all_users_from_project.sh http://nimbusserver.mfadvantageinc.com:8082 admin mfDemo\\\$20 AOS [\<domain\>]
    exit 2
fi

if [ "$5" = "" ]; then
    domain="default"
    echo "Domain: " $domain
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

#Get all users from project
echo "Getting all users from project"
response="$(curl -k --connect-timeout 5 --silent --show-error -w %{http_code} --cookie headers_and_cookies -o $4_project_users.json --header "Content-Type: application/json" --header "X-XSRF-TOKEN: $XSRFTOKEN" $1/qcbin/v2/sa/api/domains/$domain/projects/$4/users )"

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
    username=$(jq -r ".users.user[$i].name" /tmp/$4_project_users.json)

    if [ $? != 0 ]
    then
	echo "Inside if"
	# If there's only one user, there's no array
    	username=$(jq -r ".users.user.name" /tmp/$4_project_users.json)

        echo $username
        echo "Number of site users: 1"
        exit $?
    fi

    if [ $username = null ]
    then
        echo "Number of site users: " $i
        exit $?
    fi

    echo $username

    i=`expr $i + 1`
done
