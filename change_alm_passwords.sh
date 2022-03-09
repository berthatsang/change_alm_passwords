#!/bin/bash -xv

if [ "$1" = "" ] | [ "$2" = "" ] | [ "$3" = "" ]; then
    echo usage: change_alm_passwords.sh \<alm-url:port\> \<sa_username\> \<password\>
    echo example: change_alm_passwords.sh http://nimbusserver.aos.com:8082 admin Password1
    echo example: change_alm_passwords.sh http://nimbusserver.mfadvantageinc.com:8082 admin mfDemo\\\$20
    exit 2
fi

cd /tmp

#Authenticate with ALM and save cookies
echo "Authenticating with ALM for API calls..."
response="$(curl -k --connect-timeout 5 --silent --show-error --cookie-jar headers_and_cookies -w %{http_code} -d "<alm-authentication><user>$2</user><password>$3</password></alm-authentication>" --header "Content-Type: application/xml" $1/qcbin/authentication-point/alm-authenticate)"

if [ $? != 0 ]; then
   ls -l headers_and_cookies
   #rm -f headers_and_cookies
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

echo "Getting all site users"
response="$(curl -k --connect-timeout 5 --silent --show-error -w %{http_code} --cookie headers_and_cookies -o all_site_users.json --header "Content-Type: application/json" --header "X-XSRF-TOKEN: $XSRFTOKEN" $1/qcbin/v2/sa/api/site-users )"


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
    username=$(jq -r ".users.user[$i].name" /tmp/all_site_users.json)

    if [ $username = null ]
    then 
        echo "Number of site users: " $i
        exit $?
    fi

    #Update a site user
    echo "Updating user: " $username
    response="$(curl -X PUT -k --connect-timeout 5 --silent --trace-ascii ~/test.txt --show-error -w %{http_code} --cookie headers_and_cookies -d @/tmp/update_user.json --header "Content-Type: application/json" --header "X-XSRF-TOKEN: $XSRFTOKEN" $1/qcbin/v2/sa/api/site-users/$username )"
    
    if [ $? != 0 ]
    then
        echo "$?: " $?
        rm -f headers_and_cookies
        exit $?
    fi
    
    response_code="$(echo $response | grep -E -o '.{3}$')"
    if [ "$response_code" != "200" ] # 200 = success
    then
        echo "response: " $response
        echo "response_code: " $response_code
        rm -f headers_and_cookies
        exit 1
    fi

    i=`expr $i + 1`
done
