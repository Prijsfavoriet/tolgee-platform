# --- STAGE 1: Build the Webapp (Frontend) ---
FROM node:20-alpine AS webapp-build
WORKDIR /app

# 1. Copy the entire project first so Vite can see /library and /e2e
COPY . .

# 2. Go into webapp to install and build
WORKDIR /app/webapp
RUN npm ci --ignore-scripts

# 3. BYPASS: Remove Enterprise Frontend logic
RUN rm -rf src/ee

# 4. Run the build (Vite will now find /library/tsconfig.json)
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
COPY --from=webapp-build /webapp/dist /app/public
COPY --from=server-build /server/server/build/libs/*.jar /app/tolgee.jar

ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/tolgee.jar"]
