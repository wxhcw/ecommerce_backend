# 使用官方 Java 17
FROM eclipse-temurin:17-jdk

# 设置工作目录
WORKDIR /app

# 复制源码
COPY . .

# 构建 Spring Boot
RUN ./mvnw clean package -DskipTests

# 暴露 Render 需要的端口
EXPOSE 8080

# 启动应用（Render 会注入 PORT）
CMD ["sh", "-c", "java -jar target/*.jar"]