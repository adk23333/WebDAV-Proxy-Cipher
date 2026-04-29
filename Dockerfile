# --- 第一阶段：构建阶段 (Build Stage) ---
    FROM node:22 AS builder

    # 设置工作目录
    WORKDIR /app
    
    # 先复制包管理文件，利用 Docker 缓存层优化构建速度
    COPY node-proxy/package*.json ./
    
    # 安装依赖
    RUN npm install
    
    # 复制源码并执行构建
    COPY node-proxy/ .
    RUN npm run build
    
    # --- 第二阶段：运行阶段 (Production Stage) ---
    FROM node:22-alpine
    
    # 设置环境变量
    ENV NODE_ENV=production
    ENV TZ=Asia/Shanghai
    
    # 设置时区（Alpine 需要安装 tzdata 包）
    RUN apk add --no-cache tzdata \
        && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
        && echo $TZ > /etc/timezone
    
    WORKDIR /node-proxy
    
    # 只从构建阶段复制必要的产物，不带入源码和冗余依赖
    COPY --from=builder /app/dist ./dist
    COPY --from=builder /app/node_modules ./node_modules
    COPY --from=builder /app/package.json ./
    
    # 如果 index.js 在 dist 目录下，请确保路径正确
    EXPOSE 5344
    
    # 建议使用非 root 用户运行以提高安全性
    # USER node
    
    ENTRYPOINT ["node", "dist/index.js"]