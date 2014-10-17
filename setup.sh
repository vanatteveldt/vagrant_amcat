set -e

>&2 echo "*** Installing apt dependencies" 
sudo apt-get install -qy git unrtf rabbitmq-server python-pip python-dev libxml2-dev libxslt-dev lib32z1-dev postgresql postgresql-server-dev-9.3 postgresql-contrib-9.3 python-virtualenv

# Install elasticsearch first to give it time to start up
if ! type "java" > /dev/null 2>&1; then
  >&2 echo "*** Installing java"
  sudo add-apt-repository ppa:webupd8team/java
  sudo apt-get -qq update
  echo oracle-java8-installer shared/accepted-oracle-license-v1-1 select true | sudo /usr/bin/debconf-set-selections 
  # even with -qq it keeps outputting stupid progress dots. I blame Oracle. 
  sudo apt-get install -qqy oracle-java8-installer
fi

sudo rm -f /var/log/elasticsearch/elasticsearch.log
if [ ! -d "/usr/share/elasticsearch" ]; then
  >&2 echo "*** Install elastic"

  cd /tmp
  # Download and install elasticsearch
  wget -q "https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.2.deb"
  sudo dpkg -i elasticsearch-1.3.2.deb
  # Install plugins
  cd /usr/share/elasticsearch
  sudo bin/plugin -s -install elasticsearch/elasticsearch-lang-python/2.3.0
  sudo bin/plugin -s -install elasticsearch/elasticsearch-analysis-icu/2.3.0
  sudo bin/plugin -s -install mobz/elasticsearch-head
  sudo wget -q http://hmbastiaan.nl/martijn/amcat/hitcount.jar
  # Allow dynamic scripting
  echo -e "\nscript.disable_dynamic: false" | sudo tee -a /etc/elasticsearch/elasticsearch.yml
  # Monkey-patch startup file to add hit count
  sudo sed -i 's/^\(ES_HOME.*\)$/\1\nES_CLASSPATH=$ES_HOME\/hitcount.jar\nexport ES_CLASSPATH/' /etc/init.d/elasticsearch 
  sudo sed -i 's/\(DAEMON_OPTS=.*\)"$/\1 -Des.index.similarity.default.type=nl.vu.amcat.HitCountSimilarityProvider"/' /etc/init.d/elasticsearch 
fi
sudo service elasticsearch restart


function provision_git {    
    if [ ! -d "/vagrant/$2" ]; then
      >&2 echo "*** Cloning $2" 
      git clone https://github.com/$1/$2.git /vagrant/$2
    else
      >&2 echo "*** Pulling $2" 
      cd /vagrant/$2
      git pull
    fi
}

provision_git amcat amcat
provision_git vanatteveldt saf

>&2 echo "*** Installing python virtual environment"
if [ ! -d "~/amcat-env" ]; then
  virtualenv ~/amcat-env
fi
. ~/amcat-env/bin/activate
pip install -r /vagrant/amcat/requirements.txt


>&2 echo "*** Getting static files (javascript) via bower"
if ! type "bower" > /dev/null 2>&1; then
  sudo add-apt-repository ppa:chris-lea/node.js
  sudo apt-get update
  sudo apt-get install -qy nodejs
  sudo npm install -g bower
fi

cd /vagrant/amcat
bower install -s

if ! psql amcat -c '\q' 2>&1; then
  >&2 echo "*** Setup database"
  sudo -u postgres createuser -s $USER  
  createdb amcat 
fi

while ! grep -q "started$" /var/log/elasticsearch/elasticsearch.log; do
    >&2 echo "*** Waiting for elastic"
    sleep 5
done

export PYTHONPATH=/vagrant/amcat:/vagrant/saf
export DJANGO_SETTINGS_MODULE=settings

>&2 echo "*** django syncdb"
python -m amcat.manage syncdb

>&2 echo "*** starting runserver on port 8001 in screen process"
screen -S runserver -X quit || true
screen -S runserver -d -m python -m amcat.manage runserver 0.0.0.0:8001

>&2 echo "*** starting celery worker in screen process"
screen -S amcat_celery -X quit || true
screen -S amcat_celery -d -m celery -A amcat.amcatcelery worker -l info -Q amcat


>&2 echo "*** Done!"
>&2 echo "Use vagrant ssh, screen -list, and screen -r to connect to background processes"
>&2 echo "Elastic head is listening on http://localhost:9201/_plugin/head"
>&2 echo "AmCAT should be reachable on http://localhost:8001 (it might take a minute)."
>&2 echo "You can login on using username amcat, password amcat"

