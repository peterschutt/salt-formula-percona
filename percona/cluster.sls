# Copyright 2013 Hewlett-Packard Development Company, L.P.
#
#    Licensed under the Apache License, Version 2.0 (the "License"); you may
#    not use this file except in compliance with the License. You may obtain
#    a copy of the License at
#
#         http://www.apache.org/licenses/LICENSE-2.0
#
#    Unless required by applicable law or agreed to in writing, software
#    distributed under the License is distributed on an "AS IS" BASIS, WITHOUT
#    WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied. See the
#    License for the specific language governing permissions and limitations
#    under the License.
#
{% from "percona/macros.sls" import mysql_user with context %}
{% from "percona/macros.sls" import mysql_grant with context %}

include:
  - percona.common
  {# - percona.cluster_client #}  # package not in bionic apt repo

percona-server:
  debconf:
    - set
    - name: percona-xtradb-cluster-server-{{ salt['pillar.get']('percona:version', '5.7') }}
    - data:
        'percona-server-server/root_password':
          type: password
          value: {{ salt['pillar.get']('percona:passwords:root', '') }}
        'percona-server-server/root_password_again':
          type: password
          value: {{ salt['pillar.get']('percona:passwords:root', '') }}

  pkg:
    - latest
    - name: percona-xtradb-cluster-server-{{ salt['pillar.get']('percona:version', '5.7') }}
    - require:
      - debconf: percona-server

######################
## Clustercheck Script
percona-xinetd:
  pkg:
    - installed
    - name: xinetd
  service:
    - running
    - name: xinetd
    - require:
      - pkg: percona-xinetd
    - watch:
      - file: percona-xinetd
  file:
    - append
    - name: /etc/services
    - text: "mysqlchk        9200/tcp                        # Percona Clustercheck"

/usr/bin/clustercheck:
  file:
    - managed
    - source: salt://percona/templates/clustercheck.jinja
    - template: jinja
    - user: root
    - group: root
    - mode: 755
    - require:
      - pkg: percona-server

{{ mysql_user("clustercheck", "localhost", salt['pillar.get']('percona:passwords:clustercheck', '')) }}
{{ mysql_grant("clustercheck", "localhost", "*.*", grant='PROCESS') }}
