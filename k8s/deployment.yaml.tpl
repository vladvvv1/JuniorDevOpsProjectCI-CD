apiVersion: apps/v1
kind: Deployment
metadata:
  name: nodejs-app-deployment
  labels:
    app: nodejs-app
spec:
  replicas: 2
  selector:
    matchLabels:
      app: nodejs-app
  template:
    metadata:
      labels:
        app: nodejs-app
    spec:
      containers:
        - name: nodejs-app
          image: ${ACR_LOGIN_SERVER}/nodejs-app:${IMAGE_TAG}
          imagePullPolicy: Always
          ports:
            - containerPort: 3000
          env:
            - name: PORT
              value: "3000"
            - name: DATABASE_URL
              valueFrom:
                secretKeyRef:
                  name: app-db-secret
                  key: DATABASE_URL