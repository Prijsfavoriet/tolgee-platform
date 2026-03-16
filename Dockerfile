# --- STAGE 1: Build the Webapp (Frontend) ---
FROM node:20-alpine AS webapp-build
WORKDIR /app

# 1. Copy the entire project
COPY . .

# 2. Go into webapp
WORKDIR /app/webapp
RUN npm ci --ignore-scripts

# 3. BYPASS: Remove Enterprise Frontend logic
RUN rm -rf src/ee

# 4. FIX: Create the missing branch.json file so the build doesn't crash
RUN echo '{"branchName": "main", "hash": "self-hosted"}' > src/branch.json

# 5. Run the build
RUN npm run build

# --- STAGE 2: Build the Server (Backend) ---
FROM eclipse-temurin:21-jdk-alpine AS server-build
WORKDIR /server
COPY . .
# 4. Delete EE Backend logic (the "bypass")
RUN rm -rf ee
# 5. Build the JAR specifically excluding EE modules
RUN ./gradlew :server:bootJar -PexcludeEE=true

# --- STAGE 3: Final Runtime Image ---
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN apk --no-cache add curl

# 6. Copy assets from previous stages
COPY --from=webapp-build /app/webapp/dist /app/public
COPY --from=server-build /server/server/build/libs/*.jar /app/tolgee.jar

ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/tolgee.jar"]
