# 设置工作目录
WORKDIR /app

FROM node:22-alpine

# 设置环境变量
ENV NODE_ENV=production
ENV TZ=Asia/Shanghai

# 设置时区（Alpine 需要安装 tzdata 包）
RUN apk add --no-cache tzdata \
    && ln -snf /usr/share/zoneinfo/$TZ /etc/localtime \
    && echo $TZ > /etc/timezone

# 只从构建阶段复制必要的产物，不带入源码和冗余依赖
COPY ./dist ./src
COPY ./node_modules ./node_modules
COPY ./package.json ./

EXPOSE 5344

ENTRYPOINT ["node", "src/index.js"]