# --- STAGE 1: Build the Webapp (Frontend) ---
FROM node:20-alpine AS webapp-build
WORKDIR /webapp

# Copy package files
COPY webapp/package.json webapp/package-lock.json ./

# CRITICAL FIX: Add --ignore-scripts to skip the broken "prepare" tasks
RUN npm ci --ignore-scripts

# Now copy the rest of the webapp source
COPY webapp .

# Manually delete the EE folder if it was copied
RUN rm -rf src/ee

# Run the build (using the flag to skip scripts if needed)
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
