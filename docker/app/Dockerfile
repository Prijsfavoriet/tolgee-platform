# STAGE 1: Build the app from source
FROM node:20-alpine AS build-env
RUN apk add --no-cache openjdk21 bash git
WORKDIR /app
COPY . .
# CRITICAL: Delete Enterprise folders to unlock Unlimited mode
RUN rm -rf ee webapp/src/ee
# Build the app (This creates the BOOT-INF files)
RUN ./gradlew clean build -x check -x test -x installE2eDeps -Pproduction

# STAGE 2: The Runner
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app

# Copy the fresh files created in Stage 1
COPY --from=build-env /app/server-app/build/libs/server-app-*.jar app.jar
COPY --from=build-env /app/docker/app/cmd.sh cmd.sh
RUN chmod +x cmd.sh

# Environment setup
ENV fs-data-path=/data
EXPOSE 8080
ENTRYPOINT ["/app/cmd.sh"]
