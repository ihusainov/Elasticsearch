# elastic-command



**SSL**

View indexes
curl --cacert /etc/elasticsearch/certs/ca.crt -XGET -H 'kbn-version: 7.13.0'  'https://username:password@node1.local:9200/_cat/indices?v'

Delete indexes
curl --cacert /etc/elasticsearch/certs/ca.crt -XDELETE -H 'kbn-version: 7.13.0' 'https://username:password@node1.local:9200/filebeat-7.12.0-2021.05*'

Create user - best practice use Kibana Role
/usr/share/elasticsearch/bin/elasticsearch-users useradd myusername -p Password -r superuser
