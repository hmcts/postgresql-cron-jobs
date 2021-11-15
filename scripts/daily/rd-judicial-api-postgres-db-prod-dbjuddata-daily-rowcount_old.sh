#!/bin/bash
cat <<EOF
select 'judicial_user_profile Count' ;
select count (*) from dbjuddata.judicial_user_profile;
select 'dbjuddata.judicial_office_appointment Count' ;
select count (*) from dbjuddata.judicial_office_appointment;
EOF