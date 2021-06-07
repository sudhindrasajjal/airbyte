{{/* vim: set filetype=mustache: */}}
{{/*
Expand the name of the chart.
*/}}
{{- define "airbyte.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "airbyte.fullname" -}}
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

{{/*
Allow the release namespace to be overridden for multi-namespace deployments in combined charts
*/}}
{{- define "airbyte.namespace" -}}
  {{- if .Values.namespaceOverride -}}
    {{- .Values.namespaceOverride -}}
  {{- else -}}
    {{- .Release.Namespace -}}
  {{- end -}}
{{- end -}}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "airbyte.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Create the name of the service account
*/}}
{{- define "airbyte.serviceAccountName.scheduler" -}}
{{- if .Values.scheduler.serviceAccount.create -}}
{{- printf "%s-admin" ( template "airbyte.name" . ) }}
{{- end -}}
{{- end -}}

{{/*
Create common labels for Airbyte components
*/}}
{{- define "airbyte.labels" -}}
app: {{ template "airbyte.name" . }}
release: {{ .Release.Name }}
helm.sh/chart: {{ include "airbyte.chart" . }}
{{- end -}}

{{/*
Create labels for Airbyte DB component
*/}}
{{- define "airbyte.db.labels" -}}
{{ include "airbyte.db.matchLabels" . }}
{{ include "airbyte.labels" . }}
{{- if or .Chart.AppVersion .Values.db.image.tag }}
app.kubernetes.io/version: {{ .Values.db.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "airbyte.db.matchLabels" -}}
airbyte: db
{{- end -}}

{{/*
Create labels for Airbyte Scheduler component
*/}}
{{- define "airbyte.scheduler.labels" -}}
{{ include "airbyte.scheduler.matchLabels" . }}
{{ include "airbyte.labels" . }}
{{- if or .Chart.AppVersion .Values.scheduler.image.tag }}
app.kubernetes.io/version: {{ .Values.scheduler.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "airbyte.scheduler.matchLabels" -}}
airbyte: db
{{- end -}}

{{/*
Create labels for Airbyte Server component
*/}}
{{- define "airbyte.server.labels" -}}
{{ include "airbyte.server.matchLabels" . }}
{{ include "airbyte.labels" . }}
{{- if or .Chart.AppVersion .Values.server.image.tag }}
app.kubernetes.io/version: {{ .Values.server.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "airbyte.server.matchLabels" -}}
airbyte: server
{{- end -}}

{{/*
Create labels for Airbyte Temporal component
*/}}
{{- define "airbyte.temporal.labels" -}}
{{ include "airbyte.temporal.matchLabels" . }}
{{ include "airbyte.labels" . }}
{{- if or .Chart.AppVersion .Values.temporal.image.tag }}
app.kubernetes.io/version: {{ .Values.temporal.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "airbyte.temporal.matchLabels" -}}
airbyte: temporal
{{- end -}}

{{/*
Create labels for Airbyte Webapp component
*/}}
{{- define "airbyte.webapp.labels" -}}
{{ include "airbyte.webapp.matchLabels" . }}
{{ include "airbyte.labels" . }}
{{- if or .Chart.AppVersion .Values.webapp.image.tag }}
app.kubernetes.io/version: {{ .Values.webapp.image.tag | default .Chart.AppVersion | quote }}
{{- end }}
{{- end -}}

{{- define "airbyte.webapp.matchLabels" -}}
airbyte: webapp
{{- end -}}

{{/*
Create the name of the service account to use
*/}}
{{- define "airbyte.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
    {{ default (include "airbyte.fullname" .) .Values.serviceAccount.name }}
{{- else -}}
    {{ default "default" .Values.serviceAccount.name }}
{{- end -}}
{{- end -}}

{{/*
Create labels for Airbyte Config PVC component
*/}}
{{- define "airbyte.persistentVolume.config.labels" -}}
{{ include "airbyte.labels" . }}
airbyte: volume-configs
{{- end -}}

{{/*
Create labels for Airbyte Workspace PVC component
*/}}
{{- define "airbyte.persistentVolume.workspace.labels" -}}
{{ include "airbyte.labels" . }}
airbyte: volume-workspace
{{- end -}}

{{/*
Create labels for Airbyte Workspace PVC component
*/}}
{{- define "airbyte.persistentVolume.db.labels" -}}
{{ include "airbyte.labels" . }}
airbyte: volume-db
{{- end -}}

{{/*
Return the appropriate apiVersion for rbac.
*/}}
{{- define "rbac.apiVersion" -}}
{{- if .Capabilities.APIVersions.Has "rbac.authorization.k8s.io/v1" }}
{{- print "rbac.authorization.k8s.io/v1" -}}
{{- else -}}
{{- print "rbac.authorization.k8s.io/v1beta1" -}}
{{- end -}}
{{- end -}}
{{/*
Return the appropriate apiVersion for ingress.
*/}}
{{- define "ingress.apiVersion" -}}
{{- print "networking.k8s.io/v1beta1" -}}
{{- end -}}
{{/*
Return the appropriate apiVersion for deployment.
*/}}
{{- define "airbyte.deployment.apiVersion" -}}
{{- print "apps/v1" -}}
{{- end -}}