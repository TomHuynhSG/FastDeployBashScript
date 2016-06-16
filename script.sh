#!/bin/bash

function create_path_directory {
        echo "Create web directory at $directorypath..."
	sudo mkdir "$directorypath"

        echo "Configuring the owner of the folder $directorypath are www-data:root..."
        sudo chown www-data:www -R "$directorypath"

	echo "Configuring the permission 2775 for the web directory..."
	sudo chmod 2775 -R "$directorypath"
}

function create_domain_virtual_file {

	vhostStartBody="
	<VirtualHost *:80>
	ServerAdmin @webmasteremail@
	DocumentRoot @directorypath@
	ServerName @domainname@
	ServerAlias www.@domainname@

    	<Directory />
            Options FollowSymLinks
            AllowOverride None
    	</Directory>
    	<Directory @directorypath@>
            Options Indexes FollowSymLinks MultiViews
            AllowOverride All
            Order allow,deny
            allow from all
    	</Directory>"

vhostNonToWWW="
	RewriteEngine On
        RewriteCond %{HTTP_HOST} !^www\.
        RewriteRule ^(.*)$ http://www.%{HTTP_HOST}$1 [R=301,L]"

vhostWWWToNon="
RewriteEngine on
RewriteCond %{HTTP_HOST} ^www\.(.+)$ [NC]
RewriteRule ^(.*)$ http://%1$1 [L,R=301]"

vhostEnd="
</VirtualHost>"

	case $RedirectionChoice in
    	wwwToNon) vhost="$vhostStartBody $vhostWWWToNon $vhostEnd";;
    	NonToWWW) vhost="$vhostStartBody $vhostNonToWWW $vhostEnd";;
    	NoRedirection) vhost="$vhostStartBody $vhostEnd";;
	esac

	vhost=${vhost//@directorypath@/$directorypath}
	vhost=${vhost//@domainname@/$domainname}
	vhost=${vhost//@webmasteremail@/$webmasteremail}

	if [ "$OStype" == Debian ]; then

		echo "Try to create sites-avaialable folder..."
        	sudo mkdir /etc/apache2/sites-available

		vhosts_path="/etc/apache2/sites-available/$domainname.conf"

		echo "Creating a new vhost file at $vhosts_path..."
		sudo touch "$vhosts_path"
		sudo echo "$vhost" > "$vhosts_path"

		echo "Enabling site $domainname.conf in Apache..."
		sudo a2ensite "$domainname.conf"

                echo "Enabling apache mod-rewrite"
		sudo a2enmod rewrite

                echo "Reloading apache vhost config files"
                sudo service apache2 reload

		echo "Restarting Apache..."
		sudo service apache2 restart
	fi
	if [ "$OStype" == CentOS ]; then
        	echo "Need to develop for CentOS!!!"
	fi

}

function deploy_website {
	echo "Unzipping $zipfilepath into directory $directorypath"
	unzip -q "$zipfilepath" -d "$directorypath"

        echo "Configuring the owner of folder and files are www-data:root..."
        sudo chown www-data:www -R "$directorypath"

	echo "Configuring the permission 2775 for directories and 0664 for files..."
        find "$directorypath" -type d -exec sudo chmod 2775 {} \;
	find "$directorypath" -type f -exec sudo chmod 0664 {} \;
}

function install_ftp {

	ftp_config="listen=YES
anonymous_enable=NO
local_enable=YES
write_enable=YES
dirmessage_enable=YES
use_localtime=YES
xferlog_enable=YES
connect_from_port_20=YES
chroot_local_user=YES
secure_chroot_dir=/var/run/vsftpd/empty
pam_service_name=vsftpd
rsa_cert_file=/etc/ssl/certs/ssl-cert-snakeoil.pem
rsa_private_key_file=/etc/ssl/private/ssl-cert-snakeoil.key

allow_writeable_chroot=YES
pasv_enable=YES
pasv_min_port=1024
pasv_max_port=1048
pasv_address=@IPServer@
seccomp_sandbox=no

chmod_enable=YES
local_umask=002
file_open_mode=0777"

	echo "Installing vsftpd"
	sudo apt-get install vsftpd
	sudo touch /etc/vsftpd.conf
	ftp_config=${ftp_config//@IPServer@/$IPServer}
	sudo echo "$ftp_config" > /etc/vsftpd.conf
	sudo service vsftpd restart
}

function create_ftp_user {
echo "Creating FTP user now"
sudo adduser "$FTPuser"
sudo usermod -d /var/www "$FTPuser"
sudo groupadd www
sudo usermod -a -G www "$FTPuser"
}


echo -e "Hi, please enter webmaster email(ex: a@weboptimizers.com.au ): \c "
read  webmasteremail
echo -e "Please enter domain name (ex: website.com.au ): \c "
read  domainname
echo "The domain name you entered is: $domainname"
echo -e "Please enter web root directory path (ex: /var/www/website) : \c "
read  directorypath
echo "The domain name you entered is: $directorypath"
echo -e "Please enter Linux OS Type (Debian or CentOS)"
echo "1) Debian"
echo "2) CentOS"
read  OStype

case $OStype in
    1) OStype="Debian";;
    2) OStype="CentOS";;
esac

echo "The Linux OS Type you entered is: $OStype"

echo -e "So would you like to force redirection?"
echo "1) WWW to Non WWW"
echo "2) Non WWW to WWW"
echo "3) No Redirection (use both WWW and Non WWW)"
read  RedirectionChoice

case $RedirectionChoice in
    1) RedirectionChoice="wwwToNon";;
    2) RedirectionChoice="NonToWWW";;
    3) RedirectionChoice="NoRedirection";;
esac

echo "The redirection choice you entered is: $RedirectionChoice"


echo -e "Please enter path of zip file for deployment (ex: /home/user/website.zip) : \c "
read  zipfilepath

echo -e "Please enter your Server IP for FTP creation: \c "
read  IPServer

echo -e "Please enter your FTP username \c "
read  FTPuser

create_path_directory
create_domain_virtual_file
deploy_website
#install_ftp
#create_ftp_user

echo "Completed!!! Cheers :)"
