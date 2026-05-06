# Build stage
FROM node:24-alpine AS build
WORKDIR /app

# 构建参数 (Vite 必须在构建阶段拿到这些变量)
ARG VITE_FIREBASE_PROJECT_ID
ARG VITE_FIREBASE_APP_ID
ARG VITE_FIREBASE_API_KEY
ARG VITE_FIREBASE_AUTH_DOMAIN
ARG VITE_FIREBASE_FIRESTORE_DATABASE_ID
ARG VITE_FIREBASE_STORAGE_BUCKET
ARG VITE_FIREBASE_MESSAGING_SENDER_ID

# 将 ARG 转换为环境变量，供 npm run build 使用
ENV VITE_FIREBASE_PROJECT_ID=$VITE_FIREBASE_PROJECT_ID
ENV VITE_FIREBASE_APP_ID=$VITE_FIREBASE_APP_ID
ENV VITE_FIREBASE_API_KEY=$VITE_FIREBASE_API_KEY
ENV VITE_FIREBASE_AUTH_DOMAIN=$VITE_FIREBASE_AUTH_DOMAIN
ENV VITE_FIREBASE_FIRESTORE_DATABASE_ID=$VITE_FIREBASE_FIRESTORE_DATABASE_ID
ENV VITE_FIREBASE_STORAGE_BUCKET=$VITE_FIREBASE_STORAGE_BUCKET
ENV VITE_FIREBASE_MESSAGING_SENDER_ID=$VITE_FIREBASE_MESSAGING_SENDER_ID

COPY package*.json ./
RUN npm install
COPY . .
RUN npm run build

# Production stage
FROM node:24-alpine
WORKDIR /app

# 拷贝构建后的静态文件
COPY --from=build /app/dist ./dist
# 拷贝服务端代码和必要的配置文件
COPY --from=build /app/server.ts ./
COPY --from=build /app/package*.json ./
COPY --from=build /app/Makefile ./
COPY --from=build /app/control ./
COPY --from=build /app/Filter.plist ./
COPY --from=build /app/.github ./.github

# 安装生产环境依赖
RUN npm install --omit=dev
# 额外安装 tsx 确保可以在没有 devDependencies 的情况下运行 server.ts
RUN npm install -g tsx

# 设置生产环境标识
ENV NODE_ENV=production
ENV PORT=3000

EXPOSE 3000
CMD ["tsx", "server.ts"]
