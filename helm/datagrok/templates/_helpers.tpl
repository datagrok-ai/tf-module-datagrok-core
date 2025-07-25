{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "datagrok.name" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "datagrok.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "datagrok.labels" -}}
app.kubernetes.io/component: datagrok
app.kubernetes.io/instance: {{ .Release.Name }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
app.kubernetes.io/name: {{ include "datagrok.name" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
helm.sh/chart: {{ include "datagrok.chart" . }}
helm.sh/release-namespace: {{ .Release.Namespace }}
{{- end }}

{{- define "datagrok.selectorLabels" -}}
app.kubernetes.io/name: {{ include "datagrok.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}


{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "datagrok.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{- define "datagrok.imagePullSecret" }}
{{- printf "{\"auths\": {\"%s\": {\"auth\": \"%s\"}}}" .Values.imageCredentials.registry (printf "%s:%s" .Values.imageCredentials.username .Values.imageCredentials.password | b64enc) | b64enc }}
{{- end }}

{{/*
Customs
*/}}

{{- define "datagrok.secretName" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.nameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "app-%s-secret-%s" $name .Values.environment | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s-%s-secret" .Release.Name $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "datagrok.certSecretName" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- $name := default .Chart.Name .Values.certNameOverride -}}
{{- if contains $name .Release.Name -}}
{{- printf "cert-%s-%s-%s"
  .Values.ingress.subdomain
  $name
  .Values.environment
  | trunc 63 | trimSuffix "-"
}}
{{- else -}}
{{- printf "%s" $name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}
{{- end -}}

{{- define "datagrok.FullImageName" }}
{{- printf "%s/%s-%s:%s"
  .Values.image.registry
  .Values.image.prefix
  .Values.environment
  .Values.image.tag
}}
{{- end }}

{{/*
2ref: workaround till develop
*/}}
{{- define "datagrok.fqdn" }}
{{- if eq .Values.stage "production" -}}
{{- printf "%s.%s.%s" .Values.ingress.subdomain .Values.environment .Values.env_domain -}}
{{- else -}}
{{- if eq .Values.ingress.subdomain .Values.environment -}}
{{- printf "%s.%s" .Values.environment .Values.env_domain -}}
{{- else -}}
{{- printf "%s.%s.%s" .Values.ingress.subdomain .Values.environment .Values.env_domain -}}
{{- end -}}
{{- end -}}
{{- end }}
