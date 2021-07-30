# elastic-command



**SSL**

View indexes
```bash
curl --cacert /etc/elasticsearch/certs/ca.crt -XGET -H 'kbn-version: 7.13.0'  'https://username:password@node1.local:9200/_cat/indices?v'
```

Delete indexes
```bash
curl --cacert /etc/elasticsearch/certs/ca.crt -XDELETE -H 'kbn-version: 7.13.0' 'https://username:password@node1.local:9200/filebeat-7.12.0-2021.05*'
```

Create user - best practice use Kibana Role
```bash
/usr/share/elasticsearch/bin/elasticsearch-users useradd myusername -p Password -r superuser
```


```bash
# If error
"status"=>400, "error"=>{"type"=>"validation_exception", "reason"=>"Validation Failed: 1: this action would add [2] shards, but this cluster currently has [1000]/[1000] maximum normal shards open

# Need run command
curl --cacert /etc/elasticsearch/certs/ca.crt -XPUT https://username:password@node1.local:9200/_cluster/settings -H 'Content-type: application/json' --data-binary $'{"transient":{"cluster.max_shards_per_node":5100}}'
```
