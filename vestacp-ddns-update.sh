## script to add/edit files from a standard vestacp installation to enable ddns functionality in VestaCP
## may not work with newer VestaCP installation
## derived from  https://github.com/ryanbrownell/vesta, thanks Ryan for all the great work!!
## licensed under GPL v3
## version 0.1

mkdir -p /usr/local/vesta/bin
mkdir -p /usr/local/vesta/func
mkdir -p /usr/local/vesta/web/add/dns
mkdir -p /usr/local/vesta/web/add/package
mkdir -p /usr/local/vesta/web/ddns
mkdir -p /usr/local/vesta/web/edit/dns
mkdir -p /usr/local/vesta/web/edit/package
mkdir -p /usr/local/vesta/web/templates/admin
mkdir -p /usr/local/vesta/web/css
mkdir -p /usr/local/vesta/web/inc/i18n
mkdir -p /usr/local/vesta/web/js/pages

cat > /usr/local/vesta/bin/v-add-ddns <<'EOF'
#!/bin/bash
# info: add ddns for dns record
# options: USER DOMAIN RECORD_ID KEY [ID]
#
# The function for adding DDNS functionality to a DNS record.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
domain=$2
record_id=$3
key=$4
ddns_key=$key
id=''

# Includes
source $VESTA/func/main.sh
source $VESTA/func/domain.sh
source $VESTA/conf/vesta.conf


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '4' "$#" 'USER DOMAIN RECORD_ID KEY [ID]'
is_format_valid 'user' 'domain' 'record_id' 'ddns_key'
is_system_enabled "$DNS_SYSTEM" 'DNS_SYSTEM'
is_object_valid 'user' 'USER' "$user"
is_object_unsuspended 'user' 'USER' "$user"
is_object_valid 'dns' 'DOMAIN' "$domain"
is_object_unsuspended 'dns' 'DOMAIN' "$domain"
is_object_valid "dns/$domain" 'ID' "$record_id"
is_not_empty 'key' "$ddns_key"
is_ddns_unique
get_next_ddnsrecord
is_format_valid 'id'
is_object_new "ddns" 'ID' "$id"
is_package_full 'DDNS_RECORDS'


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Generating timestamp
time_n_date=$(date +'%T %F')
time=$(echo "$time_n_date" |cut -f 1 -d \ )
date=$(echo "$time_n_date" |cut -f 2 -d \ )

# Adding ddns to ddns conf
ddns_rec="ID='$id' DOMAIN='$domain' RECORD_ID='$record_id' KEY='$key'"
ddns_rec="$ddns_rec TIME='$time' DATE='$date'"
echo "$ddns_rec" >> $USER_DATA/ddns.conf
chmod 660 $USER_DATA/ddns.conf


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

#Logging
log_history "added ddns configuration for dns record $record_id on $domain"
log_event "$OK" "$ARGUMENTS"

exit
EOF

chmod +x /usr/local/vesta/bin/v-add-ddns

cat > /usr/local/vesta/bin/v-authenticate-ddns-key <<'EOF'
#!/bin/bash
# info: authenticate ddns key
# options: USER ID KEY [FORMAT]
#
# The function for authenticating a DDNS key for a DNS record.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
id=$2
key=$3
format=${4-shell}
valid='was not'

# Includes
source $VESTA/func/main.sh
source $VESTA/conf/vesta.conf

# JSON list function
json_auth() {
    IFS=$'\n'
    i=1
    objects=$(grep "ID='$id'" $USER_DATA/ddns.conf | grep "KEY='$key'" |wc -l)
    echo "{"
    while read str; do
        eval $str
        echo -n '    "'$ID'": {
        "DOMAIN": "'$DOMAIN'",
        "RECORD_ID": "'$RECORD_ID'",
        "VALID": true
    }'
        if [ "$i" -lt "$objects" ]; then
            echo ','
        else
            echo
        fi
        ((i++))
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf | grep "KEY='$key'")
    echo '}'
}

# SHELL authentication output function
shell_auth() {
    IFS=$'\n'
    echo "ID   DOMAIN   RECORD_ID   VALID"
    echo "--   ------   ---------   -----"
    while read str; do
        eval $str
        echo "$ID $DOMAIN $RECORD_ID true"
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf | grep "KEY='$key'")
}

# PLAIN authentication output function
plain_auth() {
    IFS=$'\n'
    while read str; do
        eval $str
        echo -e "$ID\t$DOMAIN\t$RECORD_ID\ttrue"
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf | grep "KEY='$key'")
}

# CSV authentication output function
csv_auth() {
    IFS=$'\n'
    echo "ID,DOMAIN,RECORD_ID,VALID"
    while read str; do
        eval $str
        echo "$ID,$DOMAIN,$RECORD_ID,true"
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf | grep "KEY='$key'")
}


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '3' "$#" 'USER ID KEY [FORMAT]'
# Intentionally do not validate any of this for security purposes.


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Authenticate DDNS key
result=$(grep "ID='$id'" $USER_DATA/ddns.conf | grep "KEY='$key'" | wc -l)
if [ "$result" == "1" ]; then
    valid="was";
fi

# Listing data
case $format in
    json)   json_auth ;;
    plain)  plain_auth ;;
    csv)    csv_auth ;;
    shell)  shell_auth |column -t ;;
esac

#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

#Logging
log_history "attempted authentication for ddns $id $valid successful "
log_event "$OK" "$ARGUMENTS"

exit
EOF

chmod +x /usr/local/vesta/bin/v-authenticate-ddns-key

cat > /usr/local/vesta/bin/v-change-ddns-dns-record-id <<'EOF'
#!/bin/bash
# info: change ddns dns record id
# options: USER ID NEWID
#
# The function for changing the ddns dns record id.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
id=$2
newid=$3

# Includes
source $VESTA/func/main.sh
source $VESTA/func/domain.sh
source $VESTA/conf/vesta.conf


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '3' "$#" 'USER ID NEWID'
is_format_valid 'user' 'id' 'newid'
is_system_enabled "$DNS_SYSTEM" 'DNS_SYSTEM'
is_object_valid 'user' 'USER' "$user"
is_object_unsuspended 'user' 'USER' "$user"
is_object_valid "ddns" 'ID' "$id"

# Get additional DDNS variables for verification
domain=$($BIN/v-get-ddns $user $id plain | cut -f2 )
record_id=$($BIN/v-get-ddns $user $id plain | cut -f3 )

is_object_valid 'dns' 'DOMAIN' "$domain"
is_object_unsuspended 'dns' 'DOMAIN' "$domain"
is_object_valid "dns/$domain" 'ID' "$newid"



#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Change ddns id and ddns dns record id
sed -i "s/^ID='$id' DOMAIN='$domain' RECORD_ID='$record_id'/ID='$id' DOMAIN='$domain' RECORD_ID='$newid'/" $USER_DATA/ddns.conf


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

# Logging
log_history "changed ddns dns record id for dns record $id (now $newid) on $domain"
log_event "$OK" "$ARGUMENTS"

exit
EOF

chmod +x /usr/local/vesta/bin/v-change-ddns-dns-record-id

cat > /usr/local/vesta/bin/v-change-ddns-key <<'EOF'
#!/bin/bash
# info: change ddns key
# options: USER ID KEY
#
# The function for changing DDNS record key.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
id=$2
key=$3
ddns_key=$key

# Includes
source $VESTA/func/main.sh
source $VESTA/conf/vesta.conf

# Get associated DDNS variables
domain=$($BIN/v-get-ddns $user $id plain | cut -f2 )
record_id=$($BIN/v-get-ddns $user $id plain | cut -f3 )


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '3' "$#" 'USER ID KEY'
is_format_valid 'user' 'id' 'ddns_key'
is_system_enabled "$DNS_SYSTEM" 'DNS_SYSTEM'
is_object_valid 'user' 'USER' "$user"
is_object_unsuspended 'user' 'USER' "$user"
is_object_valid "ddns" 'ID' "$id"
is_not_empty 'key' "$ddns_key"


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Deleting ddns from ddns conf
sed -i "/^ID='$id'/d" $USER_DATA/ddns.conf

# Generating timestamp
time_n_date=$(date +'%T %F')
time=$(echo "$time_n_date" |cut -f 1 -d \ )
date=$(echo "$time_n_date" |cut -f 2 -d \ )

# Adding ddns to ddns conf
ddns_rec="ID='$id' DOMAIN='$domain' RECORD_ID='$record_id' KEY='$key'"
ddns_rec="$ddns_rec TIME='$time' DATE='$date'"
echo "$ddns_rec" >> $USER_DATA/ddns.conf
chmod 660 $USER_DATA/ddns.conf


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

#Logging
log_history "updated ddns key for dns record $record_id on $domain"
log_event "$OK" "$ARGUMENTS"

exit
EOF

chmod +x /usr/local/vesta/bin/v-change-ddns-key

cat > /usr/local/vesta/bin/v-change-dns-record-by-ddns <<'EOF'
#!/bin/bash
# info: change dns domain record by ddns
# options: USER ID VALUE
#
# The function for changing DNS record with DDNS id.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
id=$2
dvalue=$3

# Includes
source $VESTA/func/main.sh
source $VESTA/func/domain.sh
source $VESTA/conf/vesta.conf


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '3' "$#" 'USER ID VALUE'
is_format_valid 'user' 'id' 'dvalue'
is_system_enabled "$DNS_SYSTEM" 'DNS_SYSTEM'
is_object_valid 'user' 'USER' "$user"
is_object_unsuspended 'user' 'USER' "$user"
is_object_valid "ddns" 'ID' "$id"

# Get additional DDNS variables for verification
domain=$($BIN/v-get-ddns $user $id plain | cut -f2 )
record_id=$($BIN/v-get-ddns $user $id plain | cut -f3 )

is_object_valid 'dns' 'DOMAIN' "$domain"
is_object_unsuspended 'dns' 'DOMAIN' "$domain"
is_object_valid "dns/$domain" 'ID' "$record_id"


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Get the current value of the record
current_value=$( $BIN/v-list-dns-records $user $domain plain | awk -F"\t" '$1 == "'$record_id'" { print $5 }' )

# Stop running if the current value is equal to the new value
if [ "$current_value" == "$dvalue" ]; then
    echo "No changes to the DNS were needed"
    exit
fi

# Change DNS record
$BIN/v-change-dns-record $user $domain $record_id $dvalue


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

# Restarting named
$BIN/v-restart-dns
check_result $? "DNS restart failed" >/dev/null

# Logging
log_history "ddns service successfully triggered dns record $record_id on $domain to change to $dvalue"
log_event "$OK" "$ARGUMENTS"

exit
EOF

chmod +x /usr/local/vesta/bin/v-change-dns-record-by-ddns

cat > /usr/local/vesta/bin/v-delete-ddns <<'EOF'
#!/bin/bash
# info: delete ddns for dns record
# options: USER ID [VERIFY]
#
# The function for removing DDNS functionality from the DNS record.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
id=$2
verify=${3-true}

# Includes
source $VESTA/func/main.sh
source $VESTA/conf/vesta.conf


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '2' "$#" 'USER ID [VERIFY]'
is_format_valid 'user' 'id'
is_system_enabled "$DNS_SYSTEM" 'DNS_SYSTEM'
is_object_valid 'user' 'USER' "$user"
is_object_unsuspended 'user' 'USER' "$user"
if [ "$verify" = "true" ]; then
   is_object_valid "ddns" 'ID' "$id"
fi


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Deleting ddns from ddns conf
sed -i "/^ID='$id'/d" $USER_DATA/ddns.conf


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

#Logging
log_history "deleted ddns configuration for dns record $record_id on $domain"
log_event "$OK" "$ARGUMENTS"

exit
EOF

chmod +x /usr/local/vesta/bin/v-delete-ddns

cat > /usr/local/vesta/bin/v-get-ddns <<'EOF'
#!/bin/bash
# info: get ddns for dns record
# options: USER ID [FORMAT]
#
# The function for obtaining a DDNS configuration.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
id=$2
format=${3-shell}

# Includes
source $VESTA/func/main.sh
source $VESTA/conf/vesta.conf

# JSON list function
json_list() {
    IFS=$'\n'
    i=1
    objects=$(grep "ID='$id'" $USER_DATA/ddns.conf |wc -l)
    echo "{"
    while read str; do
        eval $str
        echo -n '    "'$ID'": {
        "DOMAIN": "'$DOMAIN'",
        "RECORD_ID": "'$RECORD_ID'",
        "KEY": "'$KEY'",
        "TIME": "'$TIME'",
        "DATE": "'$DATE'"
    }'
        if [ "$i" -lt "$objects" ]; then
            echo ','
        else
            echo
        fi
        ((i++))
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf)
    echo '}'
}

# SHELL list function
shell_list() {
    IFS=$'\n'
    echo "ID   DOMAIN   RECORD_ID   KEY   TIME   DATE"
    echo "--   ------   ---------   ---   ----   ----"
    while read str; do
        eval $str
        echo "$ID $DOMAIN $RECORD_ID $KEY $TIME $DATE"
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf)
}

# PLAIN list function
plain_list() {
    IFS=$'\n'
    while read str; do
        eval $str
        echo -ne "$ID\t$DOMAIN\t$RECORD_ID\t$KEY\t$TIME\t"
        echo -e "$DATE"
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf)
}

# CSV list function
csv_list() {
    IFS=$'\n'
    echo "ID,DOMAIN,RECORD_ID,KEY,TIME,DATE"
    while read str; do
        eval $str
        echo "$ID,$DOMAIN,$RECORD_ID,$KEY,$TIME,$DATE"
    done < <(grep "ID='$id'" $USER_DATA/ddns.conf)
}


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '2' "$#" 'USER ID [FORMAT]'
is_format_valid 'user' 'id'
is_system_enabled "$DNS_SYSTEM" 'DNS_SYSTEM'
is_object_valid 'user' 'USER' "$user"
is_object_unsuspended 'user' 'USER' "$user"
is_object_valid "ddns" 'ID' "$id"


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Listing data
case $format in
    json)   json_list ;;
    plain)  plain_list ;;
    csv)    csv_list ;;
    shell)  shell_list |column -t ;;
esac


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

exit
EOF

chmod +x /usr/local/vesta/bin/v-get-ddns

cat > /usr/local/vesta/bin/v-get-ddns-for-dns-record <<'EOF'
#!/bin/bash
# info: get ddns for dns record
# options: USER DOMAIN ID [FORMAT] [VERIFY]
#
# The function for obtaining the DDNS configuration for a DNS record.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
domain=$2
record_id=$3
format=${4-shell}
verify=${5-true}

# Includes
source $VESTA/func/main.sh
source $VESTA/conf/vesta.conf

# JSON list function
json_list() {
    IFS=$'\n'
    i=1
    objects=$(grep "DOMAIN='$domain'" $USER_DATA/ddns.conf | grep "RECORD_ID='$rr
ecord_id'" |wc -l)
    echo "{"
    while read str; do
        eval $str
        echo -n '    "'$ID'": {
        "DOMAIN": "'$DOMAIN'",
        "RECORD_ID": "'$RECORD_ID'",
        "KEY": "'$KEY'",
        "TIME": "'$TIME'",
        "DATE": "'$DATE'"
    }'
        if [ "$i" -lt "$objects" ]; then
            echo ','
        else
            echo
        fi
        ((i++))
    done < <(grep "DOMAIN='$domain'" $USER_DATA/ddns.conf | grep "RECORD_ID='$ree
cord_id'" )
    echo '}'
}

# SHELL list function
shell_list() {
    IFS=$'\n'
    echo "ID   DOMAIN   RECORD_ID   KEY   TIME   DATE"
    echo "--   ------   ---------   ---   ----   ----"
    while read str; do
        eval $str
        echo "$ID $DOMAIN $RECORD_ID $KEY $TIME $DATE"
    done < <(grep "DOMAIN='$domain'" $USER_DATA/ddns.conf | grep "RECORD_ID='$ree
cord_id'" )
}

# PLAIN list function
plain_list() {
    IFS=$'\n'
    while read str; do
        eval $str
        echo -ne "$ID\t$DOMAIN\t$RECORD_ID\t$KEY\t$TIME\t"
        echo -e "$DATE"
    done < <(grep "DOMAIN='$domain'" $USER_DATA/ddns.conf | grep "RECORD_ID='$ree
cord_id'" )
}

# CSV list function
csv_list() {
    IFS=$'\n'
    echo "ID,DOMAIN,RECORD_ID,KEY,TIME,DATE"
    while read str; do
        eval $str
        echo "$ID,$DOMAIN,$RECORD_ID,$KEY,$TIME,$DATE"
    done < <(grep "DOMAIN='$domain'" $USER_DATA/ddns.conf | grep "RECORD_ID='$ree
cord_id'" )
}


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '3' "$#" 'USER DOMAIN RECORD_ID [FORMAT] [VERIFY]'
is_format_valid 'user' 'domain' 'record_id'
is_system_enabled "$DNS_SYSTEM" 'DNS_SYSTEM'
is_object_valid 'user' 'USER' "$user"
is_object_unsuspended 'user' 'USER' "$user"
if [ "$verify" = "true" ]; then
    is_object_valid 'dns' 'DOMAIN' "$domain"
    is_object_unsuspended 'dns' 'DOMAIN' "$domain"
    is_object_valid "dns/$domain" 'ID' "$record_id"
fi


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Listing data
case $format in
    json)   json_list ;;
    plain)  plain_list ;;
    csv)    csv_list ;;
    shell)  shell_list |column -t ;;
esac


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

exit
EOF

chmod +x /usr/local/vesta/bin/v-get-ddns-for-dns-record

cat > /usr/local/vesta/bin/v-list-ddns <<'EOF'
#!/bin/bash
# info: list ddns
# options: USER [FORMAT]
#
# The function for obtaining the list of all DDNS configurations for a user.


#----------------------------------------------------------#
#                    Variable&Function                     #
#----------------------------------------------------------#

# Argument definition
user=$1
format=${2-shell}

# Includes
source $VESTA/func/main.sh

# JSON list function
json_list() {
    IFS=$'\n'
    i=1
    objects=$(grep "ID=" $USER_DATA/ddns.conf |wc -l)
    echo "{"
    while read str; do
        eval $str
        echo -n '    "'$ID'": {
        "DOMAIN": "'$DOMAIN'",
        "RECORD_ID": "'$RECORD_ID'",
        "KEY": "'$KEY'",
        "TIME": "'$TIME'",
        "DATE": "'$DATE'"
    }'
        if [ "$i" -lt "$objects" ]; then
            echo ','
        else
            echo
        fi
        ((i++))
    done < <(cat $USER_DATA/ddns.conf)
    echo '}'
}

# SHELL list function
shell_list() {
    IFS=$'\n'
    echo "ID   DOMAIN   RECORD_ID   KEY   TIME   DATE"
    echo "--   ------   ---------   ---   ----   ----"
    while read str; do
        eval $str
        echo "$ID $DOMAIN $RECORD_ID $KEY $TIME $DATE"
    done < <(cat $USER_DATA/ddns.conf)
}

# PLAIN list function
plain_list() {
    IFS=$'\n'
    while read str; do
        eval $str
        echo -ne "$ID\t$DOMAIN\t$RECORD_ID\t$KEY\t$TIME\t"
        echo -e "$DATE"
    done < <(cat $USER_DATA/ddns.conf)
}

# CSV list function
csv_list() {
    IFS=$'\n'
    echo "ID,DOMAIN,RECORD_ID,KEY,TIME,DATE"
    while read str; do
        eval $str
        echo "$ID,$DOMAIN,$RECORD_ID,$KEY,$TIME,$DATE"
    done < <(cat $USER_DATA/ddns.conf)
}


#----------------------------------------------------------#
#                    Verifications                         #
#----------------------------------------------------------#

check_args '1' "$#" 'USER [FORMAT]'
is_format_valid 'user'
is_object_valid 'user' 'USER' "$user"


#----------------------------------------------------------#
#                       Action                             #
#----------------------------------------------------------#

# Listing data
case $format in
    json)   json_list ;;
    plain)  plain_list ;;
    csv)    csv_list ;;
    shell)  shell_list |column -t ;;
esac


#----------------------------------------------------------#
#                       Vesta                              #
#----------------------------------------------------------#

exit
EOF

chmod +x /usr/local/vesta/bin/v-list-ddns

if [ ! -n "$(grep DDNS /usr/local/vesta/bin/v-backup-user)" ]; then
ddnsnr=$(grep -n "# Mail domain" /usr/local/vesta/bin/v-backup-user | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-2
let ddnsnr3=ddnsnr-3
ddnsnr1=$(sed -n ${ddnsnr2}p /usr/local/vesta/bin/v-backup-user)
if [ "$ddnsnr1" == "fi" ]; then
head -n $ddnsnr3 /usr/local/vesta/bin/v-backup-user > /usr/local/vesta/bin/v-backup-user2
cat >> /usr/local/vesta/bin/v-backup-user2 <<'EOF'
    # DDNS
    echo -e "\n-- DDNS --" |tee -a $BACKUP/$user.log
    mkdir $tmpdir/ddns/
    # Backup ddns.conf
    cp $USER_DATA/ddns.conf $tmpdir/ddns/
    ddns_record=$(wc -l $USER_DATA/ddns.conf|cut -f 1 -d ' ')
    # Print total
    if [ "$ddns_record" -eq 1 ]; then
        echo -e "$(date "+%F %T") *** $ddns_record ddns configuration ***" |\
            tee -a $BACKUP/$user.log
    else
        echo -e "$(date "+%F %T") *** $ddns_record ddns configurations ***" |\
            tee -a $BACKUP/$user.log
    fi
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/bin/v-backup-user >> /usr/local/vesta/bin/v-backup-user2
mv -f /usr/local/vesta/bin/v-backup-user2 /usr/local/vesta/bin/v-backup-user
chmod +x /usr/local/vesta/bin/v-backup-user
else
echo "problem with v-backup-user"
fi
fi

if [ ! -n "$(grep DDNS /usr/local/vesta/bin/v-change-dns-record-id)" ]; then
ddnsnr=$(grep -n "exit" /usr/local/vesta/bin/v-change-dns-record-id | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/bin/v-change-dns-record-id > /usr/local/vesta/bin/v-change-dns-record-id2
cat >> /usr/local/vesta/bin/v-change-dns-record-id2 <<'EOF'
# Change related DDNS key if applicable
ddns_id=$($BIN/v-get-ddns-for-dns-record $user $domain_idn $id plain false | cut -f1 )
if [ ! -z "$ddns_id" ]; then
    $BIN/v-change-ddns-dns-record-id $user $ddns_id $newid false
fi
EOF
tail -n+"$ddnsnr" /usr/local/vesta/bin/v-change-dns-record-id >> /usr/local/vesta/bin/v-change-dns-record-id2
mv -f /usr/local/vesta/bin/v-change-dns-record-id2 /usr/local/vesta/bin/v-change-dns-record-id
chmod +x /usr/local/vesta/bin/v-change-dns-record-id
fi

if [ ! -n "$(grep DDNS /usr/local/vesta/bin/v-change-user-package)" ]; then
ddnsnr=$(grep -n -E "^DNS_RECORDS=" /usr/local/vesta/bin/v-change-user-package | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/bin/v-change-user-package > /usr/local/vesta/bin/v-change-user-package2
cat >> /usr/local/vesta/bin/v-change-user-package2 <<'EOF'
DDNS_RECORDS='$DDNS_RECORDS'
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/bin/v-change-user-package >> /usr/local/vesta/bin/v-change-user-package2
mv -f /usr/local/vesta/bin/v-change-user-package2 /usr/local/vesta/bin/v-change-user-package
chmod +x /usr/local/vesta/bin/v-change-user-package
fi

if [ ! -n "$(grep DDNS /usr/local/vesta/bin/v-delete-dns-record)" ]; then
ddnsnr=$(grep -n "Action" /usr/local/vesta/bin/v-delete-dns-record | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+2
let ddnsnr3=ddnsnr+3
head -n $ddnsnr2 /usr/local/vesta/bin/v-delete-dns-record > /usr/local/vesta/bin/v-delete-dns-record2
cat >> /usr/local/vesta/bin/v-delete-dns-record2 <<'EOF'
# Delete related DDNS key if applicable
ddns_id=$($BIN/v-get-ddns-for-dns-record $user $domain_idn $id plain false | cut -f1 )
$BIN/v-delete-ddns $user $ddns_id false

EOF
tail -n+"$ddnsnr3" /usr/local/vesta/bin/v-delete-dns-record >> /usr/local/vesta/bin/v-delete-dns-record2
mv -f /usr/local/vesta/bin/v-delete-dns-record2 /usr/local/vesta/bin/v-delete-dns-record
chmod +x /usr/local/vesta/bin/v-delete-dns-record
fi

if [ ! -n "$(grep DDNS /usr/local/vesta/bin/v-list-user-package)" ]; then
ddnsnr=$(grep -n "DNS_RECORDS\":" /usr/local/vesta/bin/v-list-user-package | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/bin/v-list-user-package > /usr/local/vesta/bin/v-list-user-package2
cat >> /usr/local/vesta/bin/v-list-user-package2 <<'EOF'
        "DDNS_RECORDS": "'$DDNS_RECORDS'",
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/bin/v-list-user-package >> /usr/local/vesta/bin/v-list-user-package2
mv -f /usr/local/vesta/bin/v-list-user-package2 /usr/local/vesta/bin/v-list-user-package

ddnsnr=$(grep -n "DNS RECORDS: " /usr/local/vesta/bin/v-list-user-package | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/bin/v-list-user-package > /usr/local/vesta/bin/v-list-user-package2
cat >> /usr/local/vesta/bin/v-list-user-package2 <<'EOF'
    echo "DDNS RECORDS:   $DDNS_RECORDS"
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/bin/v-list-user-package >> /usr/local/vesta/bin/v-list-user-package2
mv -f /usr/local/vesta/bin/v-list-user-package2 /usr/local/vesta/bin/v-list-user-package
chmod +x /usr/local/vesta/bin/v-list-user-package
sed -i 's/\\t$DNS_DOMAINS\\t$DNS_RECORDS\\t/\\t$DNS_DOMAINS\\t$DDNS_RECORDS\\t$DNS_RECORDS\\t/' /usr/local/vesta/bin/v-list-user-package
sed -i 's/,DNS_DOMAINS,DNS_RECORDS,/,DNS_DOMAINS,DDNS_RECORDS,DNS_RECORDS,/' /usr/local/vesta/bin/v-list-user-package
sed -i 's/,$DNS_DOMAINS,$DNS_RECORDS,/,$DNS_DOMAINS,$DDNS_RECORDS,$DNS_RECORDS,/' /usr/local/vesta/bin/v-list-user-package
fi

if [ ! -n "$(grep "DDNS" /usr/local/vesta/bin/v-list-user-packages)" ]; then
ddnsnr=$(grep -n "DNS_RECORDS\": " /usr/local/vesta/bin/v-list-user-packages | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/bin/v-list-user-packages > /usr/local/vesta/bin/v-list-user-packages2
cat >> /usr/local/vesta/bin/v-list-user-packages2 <<'EOF'
        "DDNS_RECORDS": "'$DDNS_RECORDS'",
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/bin/v-list-user-packages >> /usr/local/vesta/bin/v-list-user-packages2
mv -f /usr/local/vesta/bin/v-list-user-packages2 /usr/local/vesta/bin/v-list-user-packages
chmod +x /usr/local/vesta/bin/v-list-user-packages
sed -i 's/PKG   TPL   WEB   DNS   MAIL   DB   SHELL   DISK   BW/PKG   TPL   WEB   DNS DDNS MAIL   DB   SHELL   DISK   BW/' /usr/local/vesta/bin/v-list-user-packages
sed -i 's/---   ---   ---   ---   ----   --   -----   ----   --/---   ---   ---   --- ---- ----   --   -----   ----   --/' /usr/local/vesta/bin/v-list-user-packages
sed -i 's/$WEB_DOMAINS $DNS_DOMAINS/$WEB_DOMAINS $DDNS_RECORDS $DNS_DOMAINS/' /usr/local/vesta/bin/v-list-user-packages
sed -i 's/\\t$DNS_DOMAINS\\t$DNS_RECORDS\\t/\\t$DNS_DOMAINS\\t$DDNS_RECORDS\\t$DNS_RECORDS\\t/' /usr/local/vesta/bin/v-list-user-packages
sed -i 's/,DNS_DOMAINS,DNS_RECORDS,/,DNS_DOMAINS,DDNS_RECORDS,DNS_RECORDS,/' /usr/local/vesta/bin/v-list-user-packages
sed -i 's/,$DNS_DOMAINS,$DNS_RECORDS,/,$DNS_DOMAINS,$DDNS_RECORDS,$DNS_RECORDS,/' /usr/local/vesta/bin/v-list-user-packages
fi

if [ ! -n "$(grep DDNS /usr/local/vesta/bin/v-restore-user)" ]; then
ddnsnr=$(grep -n "Restarting DNS" /usr/local/vesta/bin/v-restore-user | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/bin/v-restore-user > /usr/local/vesta/bin/v-restore-user2
cat >> /usr/local/vesta/bin/v-restore-user2 <<'EOF'
    # Restoring DDNS
    echo -e  "\n-- DDNS --" |tee -a $tmpdir/restore.log
    # Unpacking ddns container
    tar xf $BACKUP/$backup -C $tmpdir ./ddns
    if [ "$?" -ne 0 ]; then
        rm -rf $tmpdir
        error="Can't unpack ddns container"
        echo "$error" |$SENDMAIL -s "$subj" $email $notify
        sed -i "/ $user /d" $VESTA/data/queue/backup.pipe
        check_result "$E_PARSING" "$error"
    fi
    ddns=$(wc -l $tmpdir/ddns/ddns.conf |cut -f 1 -d' ')
    if [ "$ddns" -eq 1 ]; then
        echo -e "$(date "+%F %T") $ddns ddns configuration" |tee -a $tmpdir/restore.log
    else
        echo -e "$(date "+%F %T") $ddns ddns configurations"|tee -a $tmpdir/restore.log
    fi
    # Restoring ddns configuration 
    cp $tmpdir/ddns/ddns.conf $USER_DATA/ddns.conf

EOF
tail -n+"$ddnsnr" /usr/local/vesta/bin/v-restore-user >> /usr/local/vesta/bin/v-restore-user2
mv -f /usr/local/vesta/bin/v-restore-user2 /usr/local/vesta/bin/v-restore-user
chmod +x /usr/local/vesta/bin/v-restore-user
fi

cat >> /usr/local/vesta/func/domain.sh <<'EOF'

#----------------------------------------------------------#
#                        DDNS                              #
#----------------------------------------------------------#
# Get next DDNS record ID
get_next_ddnsrecord(){
    if [ -z "$id" ]; then
        curr_str=$(grep "ID=" $USER_DATA/ddns.conf | cut -f 2 -d \' |\
            sort -n|tail -n1)
        id="$((curr_str +1))"
    fi
}
# Sort DDNS records
sort_ddns_records() {
    conf="$USER_DATA/ddns.conf"
    cat $conf |sort -n -k 2 -t \' >$conf.tmp
    mv -f $conf.tmp $conf
}
# Check if record is unique
is_ddns_unique() {
    records=$(grep "DOMAIN='$domain'" $USER_DATA/ddns.conf | grep "RECORD_ID='$record_id'" | wc -l)
    if [ ! "$records" = '0' ]; then
            echo "Error: only one DDNS configuration can exist for a given dns record"
            log_event "$E_INVALID" "$ARGUMENTS"
            exit $E_INVALID
    fi
}
EOF

if [ ! -n "$(grep "DDNS" /usr/local/vesta/func/main.sh)" ]; then
ddnsnr=$(grep -n 'DNS_RECORDS) ' /usr/local/vesta/func/main.sh | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/func/main.sh > /usr/local/vesta/func/main.sh2
cat >> /usr/local/vesta/func/main.sh2 <<'EOF'
        DDNS_RECORDS) used=$(wc -l $USER_DATA/ddns.conf);;
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/func/main.sh >> /usr/local/vesta/func/main.sh2
mv -f /usr/local/vesta/func/main.sh2 /usr/local/vesta/func/main.sh
ddnsnr=$(grep -n 'dbuser) ' /usr/local/vesta/func/main.sh | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/func/main.sh > /usr/local/vesta/func/main.sh2
cat >> /usr/local/vesta/func/main.sh2 <<'EOF'
                ddns_key)       is_key_format_valid "\$arg" "\$arg_name" ;;
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/func/main.sh >> /usr/local/vesta/func/main.sh2
mv -f /usr/local/vesta/func/main.sh2 /usr/local/vesta/func/main.sh
fi

cat >> /usr/local/vesta/web/css/styles.min.css <<'EOF'

.ddns-address {
  white-space: nowrap;
  overflow: auto;
  height: auto;
}
EOF

sed -i '/^);/d' /usr/local/vesta/web/inc/i18n/en.php

cat >> /usr/local/vesta/web/inc/i18n/en.php <<'EOF'
    'Enable Dynamic DNS' => 'Enable Dynamic DNS',
    'Dynamic DNS Key' => 'Dynamic DNS Key',
    'Dynamic DNS Service URL' => 'Dynamic DNS Service URL',
    'DDNS Records' => 'DDNS Records',
);
EOF

cat >> /usr/local/vesta/web/js/pages/add_dns_rec.js <<'EOF'
//
// Generates a random API key
randomString = function() {
    var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz';
    var string_length = 64;
    var randomstring = '';
    for (var i = 0; i < string_length; i++) {
        var rnum = Math.floor(Math.random() * chars.length);
        randomstring += chars.substr(rnum, 1);
    }
    document.v_add_dns_rec.v_ddns_key.value = randomstring;
}
EOF

cat >> /usr/local/vesta/web/js/pages/edit_dns_rec.js <<'EOF'
//
//
// Generates a random API key
randomString = function() {
    var chars = '0123456789ABCDEFGHIJKLMNOPQRSTUVWXTZabcdefghiklmnopqrstuvwxyz';
    var string_length = 64;
    var randomstring = '';
    for (var i = 0; i < string_length; i++) {
        var rnum = Math.floor(Math.random() * chars.length);
        randomstring += chars.substr(rnum, 1);
    }
    document.v_edit_dns_rec.v_ddns_key.value = randomstring;
    updateDdnsUrl();
};

$(document).ready(function() {
    $('input[name=v_ddns_key]').change(function(){
        updateDdnsUrl();
    });
});

updateDdnsUrl = function () {
    $('#ddns-url').val($('#ddns-base-url').val() + $('input[name=v_ddns_key]').val());
};
EOF

if [ ! -n "$(grep DDNS /usr/local/vesta/web/add/dns/index.php)" ]; then
ddnsnr=$(grep -n "empty($\_POST\['v\_val'" /usr/local/vesta/web/add/dns/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/web/add/dns/index.php > /usr/local/vesta/web/add/dns/index.php2
cat >> /usr/local/vesta/web/add/dns/index.php2 <<'EOF'
    if ($_POST['v_ddns'] && empty($_POST['v_ddns_key'])) $errors[] = 'ddns key';
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/add/dns/index.php >> /usr/local/vesta/web/add/dns/index.php2
mv -f /usr/local/vesta/web/add/dns/index.php2 /usr/local/vesta/web/add/dns/index.php

ddnsnr=$(grep -n "v\_domain = escapeshellarg($\_POST" /usr/local/vesta/web/add/dns/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
let ddnsnr3=ddnsnr-2
head -n $ddnsnr3 /usr/local/vesta/web/add/dns/index.php > /usr/local/vesta/web/add/dns/index.php2
cat >> /usr/local/vesta/web/add/dns/index.php2 <<'EOF'
    if ($_POST['v_ddns'] && strlen($_POST['v_ddns_key']) < 12 ) $_SESSION['error_msg'] = 'Field "ddns key" can not be less than 12 characters.';
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/add/dns/index.php >> /usr/local/vesta/web/add/dns/index.php2
mv -f /usr/local/vesta/web/add/dns/index.php2 /usr/local/vesta/web/add/dns/index.php

ddnsnr=$(grep -n "v_type = $\_POST\['v_type'\]" /usr/local/vesta/web/add/dns/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+2
let ddnsnr3=ddnsnr+3
head -n $ddnsnr2 /usr/local/vesta/web/add/dns/index.php > /usr/local/vesta/web/add/dns/index.php2
cat >> /usr/local/vesta/web/add/dns/index.php2 <<'EOF'
     // Add ddns record
     if (empty($_SESSION['error_msg']) && isset($_POST['v_ddns'])) {
         $v_ddns_key = escapeshellarg($_POST['v_ddns_key']);
         // Get newly created dns record
         exec (VESTA_CMD."v-list-dns-records ".$user." ".$v_domain." json", $output, $return_var);
         check_return_code($return_var,$output);
         $dns_records = json_decode(implode('', $output), true);
         $dns_record = end($dns_records);
         unset($output);
         // Create ddns record
         exec (VESTA_CMD."v-add-ddns ".$user." ".$v_domain." ".$dns_record['ID']." ".$v_ddns_key, $output, $return_var);
         check_return_code($return_var,$output);
         unset($output);
     }

EOF
tail -n+"$ddnsnr3" /usr/local/vesta/web/add/dns/index.php >> /usr/local/vesta/web/add/dns/index.php2
mv -f /usr/local/vesta/web/add/dns/index.php2 /usr/local/vesta/web/add/dns/index.php

ddnsnr=$(grep -n 'unset($v_priori' /usr/local/vesta/web/add/dns/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/web/add/dns/index.php > /usr/local/vesta/web/add/dns/index.php2
cat >> /usr/local/vesta/web/add/dns/index.php2 <<'EOF'
        unset($v_ddns);
        unset($v_ddns_key);
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/add/dns/index.php >> /usr/local/vesta/web/add/dns/index.php2
mv -f /usr/local/vesta/web/add/dns/index.php2 /usr/local/vesta/web/add/dns/index.php
fi



if [ ! -n "$(grep DDNS /usr/local/vesta/web/add/package/index.php)" ]; then
ddnsnr=$(grep -n "v_dns_records'])) " /usr/local/vesta/web/add/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/web/add/package/index.php > /usr/local/vesta/web/add/package/index.php2
cat >> /usr/local/vesta/web/add/package/index.php2 <<'EOF'
    if (!isset($_POST['v_ddns_records'])) $errors[] = __('ddns records');
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/add/package/index.php >> /usr/local/vesta/web/add/package/index.php2
mv -f /usr/local/vesta/web/add/package/index.php2 /usr/local/vesta/web/add/package/index.php

ddnsnr=$(grep -n 'arg($_POST\[.v_dns_records' /usr/local/vesta/web/add/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/web/add/package/index.php > /usr/local/vesta/web/add/package/index.php2
cat >> /usr/local/vesta/web/add/package/index.php2 <<'EOF'
    $v_ddns_records = escapeshellarg($_POST['v_ddns_records']);
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/add/package/index.php >> /usr/local/vesta/web/add/package/index.php2
mv -f /usr/local/vesta/web/add/package/index.php2 /usr/local/vesta/web/add/package/index.php

ddnsnr=$(grep -n '\.$v_dns_records\.' /usr/local/vesta/web/add/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/web/add/package/index.php > /usr/local/vesta/web/add/package/index.php2
cat >> /usr/local/vesta/web/add/package/index.php2 <<'EOF'
         $pkg .= "DDNS_RECORDS=".$v_ddns_records."\n";
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/add/package/index.php >> /usr/local/vesta/web/add/package/index.php2
mv -f /usr/local/vesta/web/add/package/index.php2 /usr/local/vesta/web/add/package/index.php

ddnsnr=$(grep -n 'mpty($v_dns_records)) $v_d' /usr/local/vesta/web/add/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/web/add/package/index.php > /usr/local/vesta/web/add/package/index.php2
cat >> /usr/local/vesta/web/add/package/index.php2 <<'EOF'
if (empty($v_ddns_records)) $v_ddns_records = "'0'";
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/add/package/index.php >> /usr/local/vesta/web/add/package/index.php2
mv -f /usr/local/vesta/web/add/package/index.php2 /usr/local/vesta/web/add/package/index.php
fi

if [ ! -n "$(grep DDNS /usr/local/vesta/web/edit/dns/index.php)" ]; then
ddnsnr=$(grep -n "Check POST request for dns domain" /usr/local/vesta/web/edit/dns/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/web/edit/dns/index.php > /usr/local/vesta/web/edit/dns/index.php2
cat >> /usr/local/vesta/web/edit/dns/index.php2 <<'EOF'
    // List ddns record
    if ((!empty($_GET['domain'])) && (!empty($_GET['record_id']))) {
    // Get ddns record
    exec (VESTA_CMD."v-get-ddns-for-dns-record ".$v_username." ".$v_domain." ".$v_record_id." json", $output, $return_var);
    $data = json_decode(implode('', $output), true);
    unset($output);
    // Parse ddns record
    if ($data) {
        reset($data);
        $v_ddns_id = key($data);
        $v_ddns_key = $data[$v_ddns_id]['KEY']; 
    }
}

EOF
tail -n+"$ddnsnr" /usr/local/vesta/web/edit/dns/index.php >> /usr/local/vesta/web/edit/dns/index.php2
mv -f /usr/local/vesta/web/edit/dns/index.php2 /usr/local/vesta/web/edit/dns/index.php

ddnsnr=$(grep -n "empty($\_POST\['save'\])) && (\!empty($\_GET\['domain'\])) && (\!empty($\_GET\['record\_id'\]))" /usr/local/vesta/web/edit/dns/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+3
let ddnsnr3=ddnsnr+4
head -n $ddnsnr2 /usr/local/vesta/web/edit/dns/index.php > /usr/local/vesta/web/edit/dns/index.php2
cat >> /usr/local/vesta/web/edit/dns/index.php2 <<'EOF'
    // Check empty fields
    if (empty($_POST['v_domain'])) $errors[] = 'domain';
    if (empty($_POST['v_rec'])) $errors[] = 'record';
    if (empty($_POST['v_type'])) $errors[] = 'type';
    if (empty($_POST['v_val'])) $errors[] = 'value';
    if ($_POST['v_ddns'] && empty($_POST['v_ddns_key'])) $errors[] = 'ddns key';
    if (!empty($errors[0])) {
        foreach ($errors as $i => $error) {
            if ( $i == 0 ) {
                $error_msg = $error;
            } else {
                $error_msg = $error_msg.", ".$error;
            }
        }
        $_SESSION['error_msg'] = __('Field "%s" can not be blank.',$error_msg);
    }
    if ($_POST['v_ddns'] && strlen($_POST['v_ddns_key']) < 12 ) $_SESSION['error_msg'] = 'Field "ddns key" can not be less than 12 characters.';
EOF
tail -n+"$ddnsnr3" /usr/local/vesta/web/edit/dns/index.php >> /usr/local/vesta/web/edit/dns/index.php2
mv -f /usr/local/vesta/web/edit/dns/index.php2 /usr/local/vesta/web/edit/dns/index.php

ddnsnr=$(grep -n 'VESTA_CMD."v-change-dns-record-id ".$v_username' /usr/local/vesta/web/edit/dns/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+5
let ddnsnr3=ddnsnr+6
head -n $ddnsnr2 /usr/local/vesta/web/edit/dns/index.php > /usr/local/vesta/web/edit/dns/index.php2
cat >> /usr/local/vesta/web/edit/dns/index.php2 <<'EOF'
        // Change ddns key
        if (((!isset($_POST['v_ddns']) || ($v_ddns_key != $_POST['v_ddns_key']))) && (empty($_SESSION['error_msg']))) {
        // Delete key
        if (!isset($_POST['v_ddns'])) {
            exec (VESTA_CMD."v-delete-ddns ".$v_username." ".$v_ddns_id." false", $output, $return_var);
            check_return_code($return_var,$output);
            $v_ddns_key = '';
            unset($output);
        // Add key
        } elseif (empty($v_ddns_key)) {
            $v_ddns_key = escapeshellarg($_POST['v_ddns_key']);
            exec (VESTA_CMD."v-add-ddns ".$v_username." ".$v_domain." ".$v_record_id." ".$v_ddns_key, $output, $return_var);
            check_return_code($return_var,$output);
            unset($output);
        // Update Key
        } else {
            $v_ddns_key = escapeshellarg($_POST['v_ddns_key']);
            exec (VESTA_CMD."v-change-ddns-key ".$v_username." ".$v_ddns_id." ".$v_ddns_key, $output, $return_var);
            check_return_code($return_var,$output);
            unset($output);
        }
    }
EOF
tail -n+"$ddnsnr3" /usr/local/vesta/web/edit/dns/index.php >> /usr/local/vesta/web/edit/dns/index.php2
mv -f /usr/local/vesta/web/edit/dns/index.php2 /usr/local/vesta/web/edit/dns/index.php
fi


if [ ! -n "$(grep DDNS /usr/local/vesta/web/edit/package/index.php)" ]; then
ddnsnr=$(grep -n '$v_dns_records = $data' /usr/local/vesta/web/edit/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/web/edit/package/index.php > /usr/local/vesta/web/edit/package/index.php2
cat >> /usr/local/vesta/web/edit/package/index.php2 <<'EOF'
$v_ddns_records = $data[$v_package]['DDNS_RECORDS'];
EOF
tail -n+"$ddnsnr" /usr/local/vesta/web/edit/package/index.php >> /usr/local/vesta/web/edit/package/index.php2
mv -f /usr/local/vesta/web/edit/package/index.php2 /usr/local/vesta/web/edit/package/index.php

ddnsnr=$(grep -n "v_dns_records'\])) \$err" /usr/local/vesta/web/edit/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/web/edit/package/index.php > /usr/local/vesta/web/edit/package/index.php2
cat >> /usr/local/vesta/web/edit/package/index.php2 <<'EOF'
    if (!isset($_POST['v_ddns_records'])) $errrors[] = __('ddns records');
EOF
tail -n+"$ddnsnr" /usr/local/vesta/web/edit/package/index.php >> /usr/local/vesta/web/edit/package/index.php2
mv -f /usr/local/vesta/web/edit/package/index.php2 /usr/local/vesta/web/edit/package/index.php

ddnsnr=$(grep -n "llarg($\_POST\['v_dns_rec" /usr/local/vesta/web/edit/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/web/edit/package/index.php > /usr/local/vesta/web/edit/package/index.php2
cat >> /usr/local/vesta/web/edit/package/index.php2 <<'EOF'
    $v_ddns_records = escapeshellarg($_POST['v_ddns_records']);
EOF
tail -n+"$ddnsnr" /usr/local/vesta/web/edit/package/index.php >> /usr/local/vesta/web/edit/package/index.php2
mv -f /usr/local/vesta/web/edit/package/index.php2 /usr/local/vesta/web/edit/package/index.php

ddnsnr=$(grep -n '\.$v_dns_records\.' /usr/local/vesta/web/edit/package/index.php | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/web/edit/package/index.php > /usr/local/vesta/web/edit/package/index.php2
cat >> /usr/local/vesta/web/edit/package/index.php2 <<'EOF'
    $pkg .= "DDNS_RECORDS=".$v_ddns_records."\n";
EOF
tail -n+"$ddnsnr" /usr/local/vesta/web/edit/package/index.php >> /usr/local/vesta/web/edit/package/index.php2
mv -f /usr/local/vesta/web/edit/package/index.php2 /usr/local/vesta/web/edit/package/index.php
fi

if [ ! -n "$(grep ddns /usr/local/vesta/web/templates/admin/add_dns_rec.html)" ]; then
ddnsnr=$(grep -n '<table class="data-col2">' /usr/local/vesta/web/templates/admin/add_dns_rec.html | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-4
let ddnsnr3=ddnsnr-5
head -n $ddnsnr3 /usr/local/vesta/web/templates/admin/add_dns_rec.html > /usr/local/vesta/web/templates/admin/add_dns_rec.html2
cat >> /usr/local/vesta/web/templates/admin/add_dns_rec.html2 <<'EOF'
                                </td>
                            </tr>
                            <tr>
                                <td class="vst-text input-label">
                                    <?php print __('Priority');?> <span class="optional">(<?php print __('optional');?>)</span>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <input type="text" size="20" class="vst-input" name="v_priority" value="<?=htmlentities(trim($v_priority, "'"))?>">
                                </td>
                            </tr>
                            <tr>
                                <td class="step-top vst-text">
                                    <label><input type="checkbox" size="20" class="vst-checkbox" name="v_ddns" <?php if(!empty($v_ddns_key)) echo "checked=yes" ?> onclick="javascript:elementHideShow('ddnstable');"> <?php print __('Enable Dynamic DNS');?></label>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <table style="display:<?php if (empty($v_ddns_key)) { echo 'none';} else {echo 'block';}?>;" id="ddnstable">
                                      <tr>
                                            <td class="vst-text input-label step-left">
                                                <?php print __('Dynamic DNS Key');?>  / <a href="javascript:randomString();" class="generate"><?php print __('generate');?></a>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td class="step-left">
                                                <input type="text" size="20" class="vst-input" name="v_ddns_key" value="<?=htmlentities(trim($v_ddns_key, "'"))?>">
                                            </td>
                                        </tr>
                                        <tr>
                                            <td class="step-left">
                                                <table width="600px">
                                                    <tr>
                                                        <td class="vst-text input-label"><?php print __('Dynamic DNS Service URL');?></td>
                                                    </tr>
                                                    <tr>
                                                        <td><span class="optional"><?php print __('You first need to add this record to get the Dynamic DNS URL');?></span></td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                    </table>
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/templates/admin/add_dns_rec.html >> /usr/local/vesta/web/templates/admin/add_dns_rec.html2
mv -f /usr/local/vesta/web/templates/admin/add_dns_rec.html2 /usr/local/vesta/web/templates/admin/add_dns_rec.html
fi

if [ ! -n "$(grep ddns /usr/local/vesta/web/templates/admin/add_package.html)" ]; then
ddnsnr=$(grep -n "php print __('Mail Domains" /usr/local/vesta/web/templates/admin/add_package.html | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/web/templates/admin/add_package.html > /usr/local/vesta/web/templates/admin/add_package.html2
cat >> /usr/local/vesta/web/templates/admin/add_package.html2 <<'EOF'
                                    <?php print __('DDNS records');?>  <span class="optional">(<?=__('all domains')?>)</span>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <input type="text" size="20" class="vst-input" name="v_ddns_records" value="<?=htmlentities(trim($v_ddns_records, "'"))?>">
                                    <img id="unlim-dns-records" class="unlim-trigger" src="/images/unlim.png" />
                                </td>
                            </tr>
                            <tr>
                                 <td class="vst-text input-label">
EOF
tail -n+"$ddnsnr" /usr/local/vesta/web/templates/admin/add_package.html >> /usr/local/vesta/web/templates/admin/add_package.html2
mv -f /usr/local/vesta/web/templates/admin/add_package.html2 /usr/local/vesta/web/templates/admin/add_package.html
fi

if [ ! -n "$(grep ddns /usr/local/vesta/web/templates/admin/edit_dns_rec.html)" ]; then
ddnsnr=$(grep -n '<table class="data-col2">' /usr/local/vesta/web/templates/admin/edit_dns_rec.html | sed -n '2p' | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-4
let ddnsnr3=ddnsnr-5
head -n $ddnsnr3 /usr/local/vesta/web/templates/admin/edit_dns_rec.html > /usr/local/vesta/web/templates/admin/edit_dns_rec.html2
cat >> /usr/local/vesta/web/templates/admin/edit_dns_rec.html2 <<'EOF'
                                </td>
                            </tr>
                            <tr>
                                <td class="step-top vst-text">
                                    <label><input type="checkbox" size="20" class="vst-checkbox" name="v_ddns" <?php if(!empty($v_ddns_key)) echo "checked=yes" ?> onclick="javascript:elementHideShow('ddnstable');"> <?php print __('Enable Dynamic DNS');?></label>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <table style="display:<?php if (empty($v_ddns_key)) { echo 'none';} else {echo 'block';}?>;" id="ddnstable">
                                      <tr>
                                            <td class="vst-text input-label step-left">
                                                <?php print __('Dynamic DNS Key');?>  / <a href="javascript:randomString();" class="generate"><?php print __('generate');?></a>
                                            </td>
                                        </tr>
                                        <tr>
                                            <td class="step-left">
                                                <input type="text" size="20" class="vst-input" name="v_ddns_key" value="<?=htmlentities(trim($v_ddns_key, "'"))?>">
                                            </td>
                                        </tr>
                                        <tr>
                                            <td class="step-left">
                                                <table width="600px">
                                                    <tr>
                                                        <td class="vst-text input-label"><?php print __('Dynamic DNS Service URL');?></td>
                                                    </tr>
                                                    <tr>
                                                        <td><span class="optional"><?php print __("To dynamically update this record's IP address, simply use CURL to fetch this URL");?>:</span></td>
                                                    </tr>
                                                    <tr>
                                                        <td>
                                                            <?php 
                                                                $v_ddns_url = "https://".$_SERVER['SERVER_ADDR'].":".$_SERVER['SERVER_PORT']."/ddns/?user=".$user."&id=".$v_ddns_id."&key=";
                                                                $v_ddns_url_key = htmlentities(trim($v_ddns_key, "'"));
                                                            ?>
                                                            <br>
                                                            <input type="hidden" value="<?=$v_ddns_url?>" id="ddns-base-url">
                                                            <textarea class="vst-textinput ddns-address" name="v_aliases" readonly="readonly" onClick="this.select();" id="ddns-url"><?=$v_ddns_url?><?=$v_ddns_url_key?></textarea>
                                                        </td>
                                                    </tr>
                                                </table>
                                            </td>
                                        </tr>
                                    </table>
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/templates/admin/edit_dns_rec.html >> /usr/local/vesta/web/templates/admin/edit_dns_rec.html2
mv -f /usr/local/vesta/web/templates/admin/edit_dns_rec.html2 /usr/local/vesta/web/templates/admin/edit_dns_rec.html
fi

if [ ! -n "$(grep ddns /usr/local/vesta/web/templates/admin/edit_package.html)" ]; then
ddnsnr=$(grep -n "php print __('Mail Domains" /usr/local/vesta/web/templates/admin/edit_package.html | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr-1
head -n $ddnsnr2 /usr/local/vesta/web/templates/admin/edit_package.html > /usr/local/vesta/web/templates/admin/edit_package.html2
cat >> /usr/local/vesta/web/templates/admin/edit_package.html2 <<'EOF'
                                    <?php print __('DDNS records');?>  <span class="optional">(<?=__('all domains')?>)</span>
                                </td>
                            </tr>
                            <tr>
                                <td>
                                    <input type="text" size="20" class="vst-input" name="v_ddns_records" value="<?=htmlentities(trim($v_ddns_records, "'"))?>">
                                    <img id="unlim-dns-records" class="unlim-trigger" src="/images/unlim.png" />
                                </td>
                            </tr>
                            <tr>
                                <td class="vst-text input-label">
EOF
tail -n+"$ddnsnr" /usr/local/vesta/web/templates/admin/edit_package.html >> /usr/local/vesta/web/templates/admin/edit_package.html2
mv -f /usr/local/vesta/web/templates/admin/edit_package.html2 /usr/local/vesta/web/templates/admin/edit_package.html
fi

if [ ! -n "$(grep ddns /usr/local/vesta/web/templates/admin/list_packages.html)" ]; then
ddnsnr=$(grep -n "data\[\$key\]\['DNS_TEMPLATE'\]?>" /usr/local/vesta/web/templates/admin/list_packages.html | awk -F: '{ print $1}')
let ddnsnr2=ddnsnr+1
head -n $ddnsnr /usr/local/vesta/web/templates/admin/list_packages.html > /usr/local/vesta/web/templates/admin/list_packages.html2
cat >> /usr/local/vesta/web/templates/admin/list_packages.html2 <<'EOF'
                    </div>
                  </div>
                </td>
                <td>
                  <div class="l-unit__stat-cols clearfix">
                    <div class="l-unit__stat-col l-unit__stat-col--left"><?=__('DDNS Records')?>:</div>
                    <div class="l-unit__stat-col l-unit__stat-col--right">
                      <b><?=__($data[$key]['DDNS_RECORDS'])?></b>
EOF
tail -n+"$ddnsnr2" /usr/local/vesta/web/templates/admin/list_packages.html >> /usr/local/vesta/web/templates/admin/list_packages.html2
mv -f /usr/local/vesta/web/templates/admin/list_packages.html2 /usr/local/vesta/web/templates/admin/list_packages.html
fi

cat > /usr/local/vesta/web/ddns/index.php <<'EOF'
<?php
// Main include
include($_SERVER['DOCUMENT_ROOT']."/api/index.php");

// Display debugger information
$debugger = false;

if (!empty($_GET['debug']) || !empty($_POST['debug'])) {
    $debugger = true;
    echo "<pre>";
}

// Refuse connections that are not running on HTTPS
if ((empty($_SERVER['HTTPS'])) || ($_SERVER['HTTPS'] == 'off')) {
    if ($debugger) {
        echo "HTTPS is required to use this API.";
    }
    die();
}

// Retrieve and sanatize incoming POST variables
if (!empty($_POST['user']) && !empty($_POST['id']) && !empty($_POST['key'])) {
    $user = escapeshellarg($_POST['user']);
    $id = escapeshellarg($_POST['id']);
    $key = escapeshellarg($_POST['key']);
    
// Retrieve and sanatize incoming GET variables
} elseif (!empty($_GET['user']) && !empty($_GET['id']) && !empty($_GET['key'])) {
    $user = escapeshellarg($_GET['user']);
    $id = escapeshellarg($_GET['id']);
    $key = escapeshellarg($_GET['key']);
}

// Verify all fields are completed
if (empty($user) || empty($id) || empty($key)) {
    if ($debugger) {
        echo "Authentication values are missing.";
    }
    die();
}

// Authenticate API key
exec (VESTA_CMD."v-authenticate-ddns-key ".$user." ".$id." ".$key." json", $output, $return_var);
$data = json_decode(implode('', $output), true);
unset($output);

// Verify successful authentication
if (!$data) {
    if ($debugger) {
        echo "Access denied.";
    }
    die();
}

// Get DDNS id.
$id = escapeshellarg(key($data));

// Get IP address of remote system
$ip_address = $_SERVER['REMOTE_ADDR'];
if (array_key_exists('HTTP_X_FORWARDED_FOR', $_SERVER)) {
    $ip_address = array_pop(explode(',', $_SERVER['HTTP_X_FORWARDED_FOR']));
}

// Sanatize variables
$new_ip = escapeshellarg($ip_address);

// Change DNS record
exec (VESTA_CMD."v-change-dns-record-by-ddns ".$user." ". $id ." ".$new_ip, $output, $return_var);
if ($debugger) {
    print_r($output);
}
unset($output);

// Output success message.
if ($debugger) {
    echo 'Complete! Attempted to set set record to ip address: ' . $new_ip;
    echo '</pre>';
}
EOF

