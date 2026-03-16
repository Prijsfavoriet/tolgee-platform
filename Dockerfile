# --- STAGE 1: Build the Webapp (Frontend) ---
FROM node:20-alpine AS webapp-build
WORKDIR /app
COPY . .
WORKDIR /app/webapp
RUN npm ci --ignore-scripts

# 1. Physically remove the Enterprise UI code
RUN rm -rf src/ee

# 2. THE CRITICAL FIX: Create a mock index.ts that returns null instead of undefined.
# This prevents "Minified React error #152"
RUN mkdir -p src/ee && echo "export const routes = { Project: () => null }; export const ee = null; export default function MockEE() { return null; }" > src/ee/index.ts

# 3. Mock the branch info required by index.tsx
RUN echo '{"branchName": "main", "hash": "self-hosted"}' > src/branch.json

# 4. Run the production build
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
