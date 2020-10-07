mapc_users=(mzagaja atomtay)
app_name=$1
ruby_version=$2
app_url=$3

## User Setup for Deploy Users
sudo adduser -q --disabled-password --gecos "" $app_name
sudo mkdir -p /var/www/$app_name/shared/config

# Edit the database configuration file
# nano /var/www/$app_name/shared/config/database.yml

sudo chown -R $app_name:$app_name /var/www/$app_name

# sudo chmod 600 /var/www/$app_name/shared/config/database.yml

# Setup a postgres db for the user if on staging. Also need to create postgres database on production.
# For production use createdb with -p 5433 while on db.live.mapc.org. For staging we do not need that switch.
sudo -u postgres createuser -d $app_name
sudo -u postgres createdb -O $app_name $app_name
# -h db.live.mapc.org -p 5433 <--- args for live. Also need to add password argument to this or .pgpass to ubuntu user.
# TODO: Need to seed database after the deploy
# TODO: Add pg_hba.conf update for the app on db.live.mapc.org, or just enable all connections to db.live.mapc.org from live.mapc.org
sudo certbot -n --nginx -d $app_url

# Setup /etc/nginx/sites-available with a config file for the server

# server {
#         listen 80;
#   listen [::]:80;

#   server_name staging.masaferoutessurvey.org;

#         root /var/www/myschoolcommute2/current/public;
#         passenger_enabled on;
#         passenger_app_env staging;
#   passenger_env_var DATABASE_URL "postgis://*REMOVED*";
#   passenger_env_var TEST whatever;
#   passenger_env_var DATABASE_TEST foo_db;

#   # include snippets/ssl-dyee.mapc.org.conf;
#   # include snippets/ssl-params.conf;
# }

# Issue: need to actually create sites-available config file from template
# See https://stackoverflow.com/a/6215113 to implement template for nginx config file.

sudo ln -s /etc/nginx/sites-available/$app_url /etc/nginx/sites-enabled/$app_url

if [[ sudo nginx -t ]]; then
   echo "nginx config ok!"
else
    exit 1
fi

sudo service nginx restart

sudo usermod -a -G rvm $app_name

# Add SSH keys of each MAPC employee to each app user and add SSH key of each MAPC person to their own user account
# Add public key for user to authorized_keys
echo 'source /usr/share/rvm/scripts/rvm' | sudo tee -a /home/$app_name/.bashrc > /dev/null
sudo su - $app_name
rvm user gemsets

# Add key of each MAPC user
for user in "${mapc_users[@]}"
do
  curl -L http://bit.ly/gh-keys | bash -s $user
done

# install ruby and bundler
rvm install $ruby_version
rvm use $ruby_version
gem install bundler

# enable git lfs
git lfs install

# add nvm
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.36.0/install.sh | bash
nvm install node
nvm alias default node
