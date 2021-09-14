#!/bin/bash
## Email iron mountain ftp status
echo -e "Hi\nPlease find attached output from Iron Mountain ftp" | mail -s "Iron Mountain ftp Output" -a /var/lib/probate2im/logs/sftp_ironmountain.log -r alliu.balogun@reform.hmcts.net  alliu.balogun@hmcts.net 
