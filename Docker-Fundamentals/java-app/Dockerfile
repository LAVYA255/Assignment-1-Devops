# ---- Java Hello World (multi-stage: compile with the JDK, ship on the JRE) ----

# Stage 1: build
FROM eclipse-temurin:21-jdk-alpine AS builder
WORKDIR /build
COPY HelloWorld.java ./
RUN javac HelloWorld.java

# Stage 2: runtime — only the compiled .class files are carried over
FROM eclipse-temurin:21-jre-alpine
WORKDIR /app
COPY --from=builder /build/*.class ./

EXPOSE 8080
CMD ["java", "HelloWorld"]
