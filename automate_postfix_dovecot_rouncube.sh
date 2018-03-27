#!/bin/bash
# pastikan sebelum run script ini mysql, apache2 sudah terinstall
# serta bind9 sudah dikonfigurasi

# file .my.cnf dibuat dan ditaruh di ~/.my.cnf
# isinya : 
#
#[client]
#user=root			# user mysql
#password=12345		# password mysql

dir_login=~/.my.cnf
echo ${dir_login}
domain = "mrxz.net" #edit sesuai domain yang digunkan untuk email server pada setup postfix

# UPDATE 
#sudo ap-get update

# install Packages for Postfix & Dovecot.
sudo apt-get install postfix postfix-mysql dovecot-core dovecot-imapd dovecot-pop3d dovecot-lmtpd dovecot-mysql -y

# password for mailuserpasswd
mailuserpasswd=12345678

sudo mysql --defaults-file=${dir_login}  <<EOF
		create database servermail;
        create user mailuser;
        GRANT SELECT ON servermail.* TO 'mailuser'@'127.0.0.1' IDENTIFIED BY '12345678';
        FLUSH PRIVILEGES;
		use servermail;
		CREATE TABLE  virtual_domains (
		id int(10) NOT NULL auto_increment,
		name varchar(40) NOT NULL,
		PRIMARY KEY (id) )
		ENGINE=InnoDB DEFAULT CHARSET=utf8;
		CREATE TABLE virtual_users ( 
		id INT NOT NULL AUTO_INCREMENT, 
		domain_id INT NOT NULL, 
		password varchar(106) NOT NULL, 
		email varchar(120) NOT NULL, 
		PRIMARY KEY (id), 
		UNIQUE KEY email (email) ) 
		ENGINE=InnoDB DEFAULT CHARSET=utf8;
		CREATE TABLE virtual_aliases ( 
		id INT NOT NULL AUTO_INCREMENT, 
		domain_id INT NOT NULL, 
		source varchar(100) NOT NULL, 
		destination varchar(100) NOT NULL, 
		PRIMARY KEY (id) ) 
		ENGINE=InnoDB DEFAULT CHARSET=utf8;
		INSERT INTO servermail.virtual_domains
		(id , name)
		VALUES
		(1, 'mrxz.net');
		INSERT INTO servermail.virtual_users
		(id,domain_id,password,email)
		VALUES
		(1,1, MD5('12345'), 'postmaster@mrxz.net');
		INSERT INTO servermail.virtual_users
		(id,domain_id,password,email)
		VALUES
		(2,1, MD5('12345'), 'user1@mrxz.net');
		INSERT INTO servermail.virtual_users
		(id,domain_id,password,email)
		VALUES
		(3,1, MD5('12345'), 'user2@mrxz.net');
		INSERT INTO servermail.virtual_aliases
		(id,domain_id,source,destination)
		VALUES
		(1,1, 'alias@mrxz..net', 'postmaster@mrxz.net');
		INSERT INTO servermail.virtual_aliases
		(id,domain_id,source,destination)
		VALUES
		(2,1, 'alias1@mrxz..net', 'user1@mrxz.net');
		INSERT INTO servermail.virtual_aliases
		(id,domain_id,source,destination)
		VALUES
		(3,1, 'alias2@mrxz..net', 'user2@mrxz.net');
		
EOF
echo "database awal selesai"
# pilih
#- Internet Site
#- FQDN==> nama domain

# setup postfix
sudo cp /etc/postfix/main.cf /etc/postfix/main.cf.orig
sudo cp /usr/share/postfix/main.cf.dist /etc/postfix/main.cf
#nano /etc/postfix/main.cf

###### postconf automate
sudo postconf -e 'queue_directory = /var/spool/postfix'
sudo postconf -e 'mail_owner = postfix'
sudo postconf -e 'myhostname = mrxz.net'
sudo postconf -e 'mydomain = mrxz.net'
sudo postconf -e 'myorigin = mrxz.net'
sudo postconf -e 'inet_interfaces = all'
#localhost.$mydomain, localhost, localhost.localdomain
sudo postconf -e 'mydestination = localhost.$mydomain, localhost'
sudo postconf -e 'relayhost ='
sudo postconf -e 'alias_maps = hash:/etc/aliases'
sudo postconf -e 'alias_database = hash:/etc/aliases'
sudo postconf -e 'recipient_delimiter = +'
sudo postconf -e 'home_mailbox = Maildir/'
sudo postconf -e 'sendmail_path = /usr/sbin/sendmail'
sudo postconf -e 'newaliases_path = /usr/sbin/newaliases'
sudo postconf -e 'mailq_path = /usr/sbin/mailq'
sudo postconf -e 'setgid_group = postdrop'
sudo postconf -e 'html_directory = no'
sudo postconf -e 'manpage_directory = /usr/share/man'
sudo postconf -e 'sample_directory = /etc/postfix'
sudo postconf -e 'readme_directory = no'
sudo postconf -e 'inet_protocols = all'
sudo postconf -e 'biff = no'
sudo postconf -e 'virtual_mailbox_domains = mysql:/etc/postfix/mysql-virtual-mailbox-domains.cf'
sudo postconf -e 'virtual_mailbox_maps = mysql:/etc/postfix/mysql-virtual-mailbox-maps.cf'
sudo postconf -e 'virtual_alias_maps = mysql:/etc/postfix/mysql-virtual-alias-maps.cf,mysql:/etc/postfix/mysql-virtual-email2email.cf'
sudo postconf -e 'smtpd_tls_cert_file=/etc/dovecot/dovecot.pem'
sudo postconf -e 'smtpd_tls_key_file=/etc/dovecot/private/dovecot.pem'
sudo postconf -e 'smtpd_use_tls=yes'
sudo postconf -e 'smtpd_tls_auth_only = yes'
sudo postconf -e 'smtpd_sasl_type = dovecot'
sudo postconf -e 'smtpd_sasl_path = private/auth'
sudo postconf -e 'smtpd_sasl_auth_enable = yes'
sudo postconf -e 'smtpd_recipient_restrictions = permit_sasl_authenticated, permit_mynetworks, reject_unauth_destination'
sudo postconf -e 'virtual_transport = lmtp:unix:private/dovecot-lmtp'

#Create a File for virtual_domains & add below lines
#nano /etc/postfix/mysql-virtual-mailbox-domains.cf
echo "user = mailuser
password = $(cat ~/mailuserpasswd.txt)
hosts = 127.0.0.1
dbname = servermail
query = SELECT 1 FROM servermail.virtual_domains WHERE name='%s'" > /etc/postfix/mysql-virtual-mailbox-domains.cf

#Create a file for virtual_users & add below lines.
# vim /etc/postfix/mysql-virtual-mailbox-maps.cf
echo "user = mailuser
password = $(cat ~/mailuserpasswd.txt)
hosts = 127.0.0.1
dbname = servermail
query = SELECT 1 FROM servermail.virtual_users WHERE email='%s'" > /etc/postfix/mysql-virtual-mailbox-maps.cf

# a file for virtual_aliases & add below lines.
# vim /etc/postfix/mysql-virtual-alias-maps.cf
echo "user = mailuser
password = $(cat ~/mailuserpasswd.txt)
hosts = 127.0.0.1
dbname = servermail
query = SELECT destination FROM servermail.virtual_aliases WHERE source='%s'" > /etc/postfix/mysql-virtual-alias-maps.cf

#Create a file for virtual-email2email & add below lines.
# vim /etc/postfix/mysql-virtual-email2email.cf
echo "user = mailuser
password = $(cat ~/mailuserpasswd.txt)
hosts = 127.0.0.1
dbname = servermail
query = SELECT email FROM servermail.virtual_users WHERE email='%s'" > /etc/postfix/mysql-virtual-email2email.cf

sudo service postfix restart

sudo cp /etc/postfix/master.cf /etc/postfix/master.cf.orig
sudo postconf -M submission/inet="submission   inet   n   -   y   -   -   smtpd"
sudo postconf -P "submission/inet/syslog_name=postfix/submission"
sudo postconf -P "submission/inet/smtpd_tls_security_level=encrypt"
sudo postconf -P "submission/inet/smtpd_sasl_auth_enable=yes"
sudo postconf -P "submission/inet/smtpd_client_restrictions=permit_sasl_authenticated,reject"
sudo postconf -P "submission/inet/milter_macro_daemon_name=ORIGINATING"
sudo postconf -M smtps/inet="smtps   inet   n   -   y   -   -   smtpd"
sudo postconf -P "smtps/inet/syslog_name=postfix/smtps"
sudo postconf -P "smtps/inet/smtpd_tls_wrappermode=yes"

sudo service postfix restart

#dovecot.conf
cp /etc/dovecot/dovecot.conf /etc/dovecot/dovecot.conf.orig
dir_dovecot_conf=/etc/dovecot/dovecot.conf
sudo echo "protocols = imap pop3 lmtp" >> ${dir_dovecot_conf}

#Configure 10-mail.conf by Modify the below lines.
cp /etc/dovecot/conf.d/10-mail.conf /etc/dovecot/conf.d/10-mail.conf.orig
dir_10_mail_conf=/etc/dovecot/conf.d/10-mail.conf
echo "# semua keterangan ada di file original /etc/dovecot/conf.d/10-mail.conf.orig
mail_location = maildir:/var/mail/vhosts/%d/%n

namespace inbox {
  #type = private
  #separator =
  #prefix =
  #location =
  inbox = yes
  #hidden = no
  #list = yes
  #subscriptions = yes
}

# Example shared namespace configuration
#namespace {
  #type = shared
  #separator = /
  #prefix = shared/%%u/
  #location = maildir:%%h/Maildir:INDEX=~/Maildir/shared/%%u
  #subscriptions = no
  #list = children
#}

#mail_shared_explicit_inbox = no
#mail_uid =
#mail_gid =
mail_privileged_group = mail
#mail_access_groups =
#mail_full_filesystem_access = no
#mail_attribute_dict =
#mail_server_comment = ""
#mail_server_admin =

##
## Mail processes
##
#mmap_disable = no
#dotlock_use_excl = yes
#mail_fsync = optimized
#lock_method = fcntl
#mail_temp_dir = /tmp
#first_valid_uid = 500
#last_valid_uid = 0
#first_valid_gid = 1
#last_valid_gid = 0
#mail_max_keyword_length = 50
#valid_chroot_dirs =
#mail_chroot =
#auth_socket_path = /var/run/dovecot/auth-userdb
#mail_plugin_dir = /usr/lib/dovecot/modules
#mail_plugins =

##
## Mailbox handling optimizations
##
#mailbox_list_index = no
#mail_cache_min_mail_count = 0
#mailbox_idle_check_interval = 30 secs
#mail_save_crlf = no
#mail_prefetch_count = 0
#mail_temp_scan_interval = 1w

##
## Maildir-specific settings
##
#maildir_stat_dirs = no
#maildir_copy_with_hardlinks = yes
#maildir_very_dirty_syncs = no
#maildir_broken_filename_sizes = no
#maildir_empty_new = no

##
## mbox-specific settings
##

#mbox_read_locks = fcntl
#mbox_write_locks = fcntl dotlock
#mbox_lock_timeout = 5 mins
#mbox_dotlock_change_timeout = 2 mins
#mbox_dirty_syncs = yes
#mbox_very_dirty_syncs = no
#mbox_lazy_writes = yes
#mbox_min_index_size = 0
#mbox_md5 = apop3d

##
## mdbox-specific settings
##
#mdbox_rotate_size = 2M
#mdbox_rotate_interval = 0
#mdbox_preallocate_space = no

##
## Mail attachments
##
#mail_attachment_dir =
#mail_attachment_min_size = 128k
#mail_attachment_fs = sis posix
#mail_attachment_hash = %{sha1}" > ${dir_10_mail_conf}
echo "10-mail.conf <========= SELESAI =========>"

#Configure 10-auth.conf by Modify the below lines.
cp /etc/dovecot/conf.d/10-auth.conf /etc/dovecot/conf.d/10-auth.conf.orig
dir_10_auth_conf=/etc/dovecot/conf.d/10-auth.conf
echo "## Authentication processes
##
disable_plaintext_auth = no
#auth_cache_size = 0
#auth_cache_ttl = 1 hour
#auth_cache_negative_ttl = 1 hour
#auth_realms =
#auth_default_realm =
#auth_username_chars = abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ01234567890.-_@
#auth_username_translation =
#auth_username_format = %Lu
#auth_master_user_separator =
#auth_anonymous_username = anonymous
#auth_worker_max_count = 30
#auth_gssapi_hostname =
#auth_krb5_keytab =
#auth_use_winbind = no
#auth_winbind_helper_path = /usr/bin/ntlm_auth
#auth_failure_delay = 2 secs
#auth_ssl_require_client_cert = no
#auth_ssl_username_from_cert = no
auth_mechanisms = plain login

## Password and user databases
##
#!include auth-deny.conf.ext
#!include auth-master.conf.ext

#!include auth-system.conf.ext
!include auth-sql.conf.ext
#!include auth-ldap.conf.ext
#!include auth-passwdfile.conf.ext
#!include auth-checkpassword.conf.ext
#!include auth-vpopmail.conf.ext
#!include auth-static.conf.ext" > ${dir_10_auth_conf}
echo "10-auth.conf <========= SELESAI =========>"

#Check the permession of /var/vmail.It should be same as below.
sudo mkdir -p /var/mail/vhosts/${domain}
sudo groupadd -g 5000 vmail
sudo useradd -g vmail -u 5000 vmail -d /var/mail
sudo chown -R vmail:vmail /var/mail

#Edit the auth-sql.conf.ext file & uncomment below lines.
cp /etc/dovecot/conf.d/auth-sql.conf.ext /etc/dovecot/conf.d/auth-sql.conf.ext.orig
dir_auth_sql_conf_ext=/etc/dovecot/conf.d/auth-sql.conf.ext

echo "# Authentication for SQL users. Included from 10-auth.conf.
passdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
#userdb {
#  driver = prefetch
#}

userdb {
  driver = sql
  args = /etc/dovecot/dovecot-sql.conf.ext
}
userdb {
  driver = static
  args = uid=vmail gid=vmail home=/var/mail/vhosts/%d/%n
}" > ${dir_auth_sql_conf_ext}
echo "auth-sql.conf.ext <========= SELESAI =========>"

#Uncomment & Modify dovecot-sql.conf.ext
cp /etc/dovecot/dovecot-sql.conf.ext /etc/dovecot/dovecot-sql.conf.ext.orig
dir_dovecot_sql_conf_ext=/etc/dovecot/dovecot-sql.conf.ext

echo "# Database driver: mysql, pgsql, sqlite
driver = mysql
connect = host=127.0.0.1 dbname=servermail user=mailuser password=12345678
default_pass_scheme = MD5
password_query = SELECT email as user, password FROM servermail.virtual_users WHERE email='%u';
#user_query = \
#password_query = \
#iterate_query = SELECT username AS user FROM users" > ${dir_dovecot_sql_conf_ext}
echo "dovecot-sql.conf.ext <========= SELESAI =========>"

#Change the owner,group & permissions  of /etc/dovecot
sudo chown -R vmail:dovecot /etc/dovecot
sudo chmod -R o-rwx /etc/dovecot

# Modify & uncomment the 10-master.conf file as shown below
cp /etc/dovecot/conf.d/10-master.conf /etc/dovecot/conf.d/10-master.conf.orig
dir_10_master_conf=/etc/dovecot/conf.d/10-master.conf

echo "#default_process_limit = 100
#default_client_limit = 1000
#default_vsz_limit = 256M
#default_login_user = dovenull
#default_internal_user = dovecot

service imap-login {
        inet_listener imap {
                port = 143
        }
        inet_listener imaps {
                #port = 993
                #ssl = yes
        }
}
service pop3-login {
        inet_listener pop3 {
                port = 110
        }
        inet_listener pop3s {
                #port = 995
        #ssl = yes
        }
}
service lmtp {
        unix_listener /var/spool/postfix/private/dovecot-lmtp {
                mode = 0600
                user = postfix
                group = postfix
        }
        # Create inet listener only if you can't use the above UNIX socket
        #inet_listener lmtp {
                # Avoid making LMTP visible for the entire internet
                #address =
                #port =
        #}
}
service imap {
        #vsz_limit = $default_vsz_limit
        #process_limit = 1024
}
service pop3 {
        # Max. number of POP3 processes (connections)
        #process_limit = 1024
}
service auth {
        unix_listener auth-userdb {
                mode = 0666
                user = vmail
                #group =
        }
        # Postfix smtp-auth
        unix_listener /var/spool/postfix/private/auth {
                mode = 0666
                user = postfix
                group = postfix
        }
        # Auth process is run as this user.
        user = dovecot
}
service auth-worker {
        user = vmail
}" > ${dir_10_master_conf}
echo "10-master.conf <========= SELESAI =========>"

sudo service postfix restart
sudo service dovecot restart

##############################################
##ROUNDCUBE
sudo apt-get install php-curl php-xml php-gettext php-cgi php-mysql libcurl3 libcurl3-dev php-mbstring php7.0-mbstring php-gettext -y

exists=$(sudo mysql --defaults-file=${dir_login} <<QUERY_INPUT
        SHOW GLOBAL VARIABLES LIKE 'validate_password%';
        select FOUND_ROWS();
QUERY_INPUT
)
check=$(echo $exists | sed 's/.*\s//')
if [ $check  -gt 0 ]
then
	sudo mysql --defaults-file=${dir_login} -e "UNINSTALL PLUGIN validate_password;"
	echo "uninstall validate_password success"
fi

sudo mysql --defaults-file=${dir_login}  <<EOF
        create database roundcubedb;
        create user roundcube;
        GRANT ALL PRIVILEGES ON roundcubedb.* TO 'roundcube'@'localhost' IDENTIFIED BY '12345678';
        FLUSH PRIVILEGES;
EOF

#cd /var/www/html
#exec bash
sudo mkdir /var/www/html/roundcube
file=roundcubemail-1.3.5-complete.tar.gz
if [ -e ${file} ]
then
    echo "File roundcubemail-1.3.5-complete.tar.gz sudah ada!"
else
    sudo wget https://raw.githubusercontent.com/marioxz/File/master/roundcubemail-1.3.5-complete.tar.gz
fi

sudo tar -xzf roundcubemail-1.3.5-complete.tar.gz -C /var/www/html/roundcube/
#cd roundcubemail-1.3.5
#exec bash

sudo mv /var/www/html/roundcube/roundcubemail-1.3.5/* /var/www/html/roundcube
sudo cp /var/www/html/roundcube/config/config.inc.php.sample  /var/www/html/roundcube/config/config.inc.php

sudo mysql --defaults-file=${dir_login} roundcubedb < /var/www/html/roundcube/SQL/mysql.initial.sql
echo "sql selesai"

dir=/var/www/html/roundcube/config/config.inc.php
### db_dsnw
del_num=$(sed -n "\|\$config\['db_dsnw'\]|=" ${dir})
if [ "$del_num" -ne 0 ]
then
        sed -i "${del_num}d" ${dir}
        sed -i "${del_num}i \$config\['db_dsnw'\] = 'mysql://roundcube:12345678@localhost/roundcubedb';" ${dir}
fi

### default_host
del_num=$(sed -n "\|\$config\['default_host'\]|=" ${dir})
if [ "$del_num" -ne 0 ]
then
        sed -i "${del_num}d" ${dir}
        sed -i "${del_num}i \$config\['default_host'\] = 'tls://%n';" ${dir}
fi

### smtp_server
del_num=$(sed -n "\|\$config\['smtp_server'\]|=" ${dir})
if [ "$del_num" -ne 0 ]
then
        sed -i "${del_num}d" ${dir}
        sed -i "${del_num}i \$config\['smtp_server'\] = 'tls://127.0.0.1';" ${dir}
fi

### smtp_user
del_num=$(sed -n "\|\$config\['smtp_user'\]|=" ${dir})
if [ "$del_num" -ne 0 ]
then
        sed -i "${del_num}d" ${dir}
        sed -i "${del_num}i \$config\['smtp_user'\] = '%u';" ${dir}
fi

### smtp_pass
del_num=$(sed -n "\|\$config\['smtp_pass'\]|=" ${dir})
if [ "$del_num" -ne 0 ]
then
        sed -i "${del_num}d" ${dir}
        sed -i "${del_num}i \$config\['smtp_pass'\] = '%p';" ${dir}
fi

echo "\$config['imap_conn_options'] = array(
'ssl' => array(
'verify_peer' => false,
'verfify_peer_name' => false,
),
);
\$config['smtp_conn_options'] = array(
'ssl' => array(
'verify_peer' => false,
'verify_peer_name' => false,
),
);" >> ${dir}
  
sudo chmod -R 755 /var/www/html/roundcube
sudo service apache2 restart

