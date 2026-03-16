# --- STAGE 1: Build the Webapp (Frontend) ---
FROM node:20-alpine AS webapp-build
WORKDIR /app
COPY . .
WORKDIR /app/webapp
RUN npm ci --ignore-scripts

# 1. Clear out the old attempts
RUN rm -rf src/ee

# 2. THE RIGOROUS MOCK: 
# This creates a "Proxy" object. 
# It tells React: "No matter what component you look for in 'ee', I will give you a blank box that returns null."
RUN mkdir -p src/ee && echo "const component = () => null; \
export const routes = new Proxy({}, { get: () => component }); \
export const ee = new Proxy({}, { get: () => component }); \
export default component;" > src/ee/index.ts

# 3. Finalize branch info
RUN echo '{"branchName": "main", "hash": "self-hosted"}' > src/branch.json

# 4. Build
RUN npm run build

# --- STAGE 2: Build the Server (Backend) ---
FROM eclipse-temurin:21-jdk-alpine AS server-build
WORKDIR /server
COPY . .
RUN rm -rf ee

COPY --from=webapp-build /app/webapp/dist/ /server/backend/app/src/main/resources/static/
RUN ./gradlew :server:bootJar -PexcludeEE=true --no-daemon

# --- STAGE 3: Final Runtime Image ---
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
RUN apk --no-cache add curl
COPY --from=server-build /server/backend/app/build/libs/*.jar /app/tolgee.jar

ENV SPRING_PROFILES_ACTIVE=prod
EXPOSE 8080
ENTRYPOINT ["java", "-jar", "/app/tolgee.jar"]
