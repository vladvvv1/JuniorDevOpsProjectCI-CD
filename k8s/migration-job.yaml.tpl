apiVersion: batch/v1
kind: Job
metadata:
  name: ${JOB_NAME}
  namespace: default
spec:
  ttlSecondsAfterFinished: 600
  backoffLimit: 0
  template:
    metadata:
      name: db-migration-pod
    spec:
      restartPolicy: Never
      containers:
        - name: migration-container
          image: ${ACR_LOGIN_SERVER}/db-migration:${IMAGE_TAG}
          imagePullPolicy: Always
          command:
            - "/bin/sh"
            - "-c"
            - "PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f 01-init.sql && PGPASSWORD=$DB_PASSWORD psql -h $DB_HOST -U $DB_USER -d $DB_NAME -f 02-import.sql"
          env:
            - name: DB_HOST
              valueFrom:
                secretKeyRef:
                  name: app-db-secret
                  key: DB_HOST
            - name: DB_USER
              valueFrom:
                secretKeyRef:
                  name: app-db-secret
                  key: DB_USER
            - name: DB_PASSWORD
              valueFrom:
                secretKeyRef:
                  name: app-db-secret
                  key: DB_PASSWORD
            - name: DB_NAME
              value: "portfolio"
            - name: PGSSLMODE
              value: "require"