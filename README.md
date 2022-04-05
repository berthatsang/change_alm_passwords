# Overview
This directory contains some scripts for ALM Quality Center

## change_alm_passwords
Changes all ALM Quality Center site users password. 

### Install
Copy update_user.json into /tmp

### Usage
usage: change_alm_passwords.sh <alm-url:port> <sa_username> <password>  
example: change_alm_passwords.sh http://nimbusserver.aos.com:8082 admin Password1  
example: change_alm_passwords.sh http://nimbusserver.mfadvantageinc.com:8082 admin mfDemo\$20

## get_all_users_for_project.sh
Returns all the Users for a given Project

### Usage
usage: get_all_users_from_project.sh <alm-url:port> <sa_username> <password> <project> [<domain>]
example: get_all_users_from_project.sh http://nimbusserver.aos.com:8082 admin Password1 ESIG [<domain>]
example: get_all_users_from_project.sh http://nimbusserver.mfadvantageinc.com:8082 admin mfDemo\$20 AOS [<domain>]

## get_user_projects.sh
Returns all the Projects for a given User

### Usage
usage: get_user_projects.sh <alm-url:port> <sa_username> <password> <user>
example: get_user_projects.sh http://nimbusserver.aos.com:8082 admin Password1 sa
example: get_user_projects.sh http://nimbusserver.mfadvantageinc.com:8082 admin mfDemo\$20 alex_alm
