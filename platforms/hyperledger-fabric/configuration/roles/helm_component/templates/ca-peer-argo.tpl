apiVersion: argoproj.io/v1alpha1
kind: Application
metadata:
  name: {{ component_name }}-ca
  namespace: argocd
spec:
  project: default
  source:
    repoURL: https://github.com/Karthikey22/bevel.git
    path: {{ charts_dir }}/ca
    targetRevision: HEAD
    helm:
      releaseName:  {{ component_name }}
      values: |-
{% if network.env.annotations is defined %}
        deployment:
          annotations:
{% for item in network.env.annotations.deployment %}
{% for key, value in item.items() %}
            - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
        annotations:  
          service:
{% for item in network.env.annotations.service %}
{% for key, value in item.items() %}
            - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
          pvc:
{% for item in network.env.annotations.pvc %}
{% for key, value in item.items() %}
           - {{ key }}: {{ value | quote }}
{% endfor %}
{% endfor %}
{% endif %}
        metadata:
          namespace: {{ component_name | e }}
          images:
            alpineutils: {{ alpine_image }}
            ca: {{ ca_image }}
        server:
          name: {{ component_services.ca.name }}
          tlsstatus: true
          admin: {{ component }}-admin
    {% if component_services.ca.configpath is defined %}
          configpath: conf/fabric-ca-server-config-{{ component }}.yaml
    {% endif %}        
        storage:
          storageclassname: {{ component | lower }}sc
          storagesize: 512Mi 
        vault:
          role: vault-role
          address: {{ vault.url }}
          authpath: {{ network.env.type }}{{ component_name }}-auth
          secretcert: {{ vault.secret_path | default('secretsv2') }}/data/crypto/ordererOrganizations/{{ component_name | e }}/ca?ca.{{ component_name | e }}-cert.pem
          secretkey: {{ vault.secret_path | default('secretsv2') }}/data/crypto/ordererOrganizations/{{ component_name | e }}/ca?{{ component_name | e }}-CA.key
          secretadminpass: {{ vault.secret_path | default('secretsv2') }}/data/credentials/{{ component_name | e }}/ca/{{ component }}?user
          serviceaccountname: vault-auth
          imagesecretname: regcred
        service:
          servicetype: ClusterIP
          ports:
            tcp:
              port: {{ component_services.ca.grpc.port }}
    {% if component_services.ca.grpc.nodePort is defined %}
              nodeport: {{ component_services.ca.grpc.nodePort }}
    {% endif %}
    proxy:
          provider: {{ network.env.proxy }}
          type: peer
          external_url_suffix: {{ external_url_suffix }}
  destination:
    server: "https://kubernetes.default.svc"
    namespace: {{ component_name }}
  syncPolicy:
    automated:
      # Do not enable pruning yet!
      prune: false # Specifies if resources should be pruned during auto-syncing ( false by default ).
      selfHeal: true

