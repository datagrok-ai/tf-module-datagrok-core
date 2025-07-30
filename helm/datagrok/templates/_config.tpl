{{- define "datagrok.configJSON" -}}
{
  "deployDemo": false,
  "dbServer": "{{ .Values.datagrok.sql.host }}",
  "db": "{{ .Values.datagrok.sql.database }}",
  "dbAdminLogin": "{{ .Values.datagrok.db_admin_user }}",
  "dbAdminPassword": "{{ .Values.datagrok.db_admin_password }}",
  "dbLogin": "{{ .Values.datagrok.sql.user }}",
  "dbPassword": "{{ .Values.datagrok.sql.password }}",
  "adminPassword": "admin",
  "adminDevKey": "admin",
  "useAdminForMigrations": false,
  "isolatesCount": 2,
  "googleStorageCredentials": {{ include "datagrok.credentialsStorage" . | quote }},
  "googleStorageProject": "{{ .Values.datagrok.storage.project }}",
  "googleStorageBucket": "{{ .Values.datagrok.storage.bucket }}",
  "connectorsSettings": {
    "dataframeParsingMode":"New Process",
    "externalDataFrameCompress":true,
    "grokConnectHost":"datagrok-grok-connect",
    "grokConnectPort":1234,
    "localFileSystemAccess":false,
    "sambaSpaceEscape":"none",
    "sambaVersion":"3.0"
  },
  "dockerSettings": {
      "grokSpawnerApiKey": "test-x-api-key",
      "grokSpawnerHost": "grok_spawner",
      "grokSpawnerPort": 8000,
      "imageBuildTimeoutMinutes": 30,
      "proxyRequestTimeout": 60000
  },
  "queueSettings": {
    "amqpHost": "{{ .Values.datagrok.rabbitmq }}",
    "amqpPassword": "guest",
    "amqpPort": 5672,
    "amqpUser": "guest",
    "pipeHost": "grok_pipe",
    "pipeKey": "test-key"
  }
}

{{- end -}}