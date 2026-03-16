# --- STAGE 1: Build the Webapp (Frontend) ---
FROM node:20-alpine AS webapp-build
WORKDIR /webapp
COPY webapp/package.json webapp/package-lock.json ./
RUN npm ci
COPY webapp .
# BYPASS: Remove Enterprise Frontend logic
RUN rm -rf src/ee
RUN npm run build:production

# --- STAGE 2: Build the Server (Backend) ---
FROM eclipse-temurin:21-jdk-alpine AS server-build
WORKDIR /server
COPY . .
# BYPASS: Remove Enterprise Backend logic
RUN rm -rf ee
# Build the JAR without EE modules
RUN ./gradlew :server:bootJar -PexcludeEE=true

# --- STAGE 3: Final Runtime Image ---
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN apk --no-cache add curl
COPY --from=webapp-build /webapp/dist /app/public
COPY --from=server-build /server/server/build/libs/*.jar /app/tolgee.jar

ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
# No VOLUME /data here to ensure Railway compatibility
ENTRYPOINT ["java", "-jar", "/app/tolgee.jar"]
