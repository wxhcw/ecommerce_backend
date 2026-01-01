# 多阶段构建 Dockerfile for Spring Boot 应用

# 阶段 1: 构建阶段
FROM maven:3.9-eclipse-temurin-17 AS build
WORKDIR /app

# 复制 pom.xml 和源代码
COPY pom.xml .
COPY src ./src

# 构建应用（跳过测试以加快构建速度）
RUN mvn clean package -DskipTests

# 阶段 2: 运行阶段
FROM eclipse-temurin:17-jre-alpine
WORKDIR /app

# 安装 curl 用于健康检查
RUN apk add --no-cache curl

# 创建非 root 用户
RUN addgroup -S spring && adduser -S spring -G spring
USER spring:spring

# 从构建阶段复制 JAR 文件
COPY --from=build /app/target/*.jar app.jar

# 暴露端口（Render 会通过 PORT 环境变量设置）
EXPOSE 8080

# 健康检查（使用根路径）
HEALTHCHECK --interval=30s --timeout=3s --start-period=40s --retries=3 \
  CMD curl -f http://localhost:${PORT:-8080}/ || exit 1

# 启动应用
# 注意：Render 会设置 PORT 环境变量，Spring Boot 需要监听该端口
# 设置 Spring profile 为 prod
ENTRYPOINT ["sh", "-c", "java -jar -Dspring.profiles.active=prod -Dserver.port=${PORT:-8080} app.jar"]
