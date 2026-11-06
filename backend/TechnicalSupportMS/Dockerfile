# ─────────────────────────────────────────────
#  Stage 1 – Build
#  Uses maven:3.9 image (no mvnw needed)
# ─────────────────────────────────────────────
FROM maven:3.9-eclipse-temurin-17-alpine AS builder

WORKDIR /app

# Copy pom first (layer-cache friendly)
COPY pom.xml .

# Download dependencies
RUN mvn dependency:go-offline -B -Dmaven.test.skip=true

# Copy source code and build
COPY src src
RUN mvn package -Dmaven.test.skip=true -B

# ─────────────────────────────────────────────
#  Stage 2 – Runtime
# ─────────────────────────────────────────────
FROM eclipse-temurin:17-jre-alpine

WORKDIR /app

RUN addgroup -S catchopp && adduser -S catchopp -G catchopp
USER catchopp

COPY --from=builder /app/target/TechnicalSupportMS-0.0.1-SNAPSHOT.jar app.jar

EXPOSE 8087

ENTRYPOINT ["java", "-jar", "app.jar"]
