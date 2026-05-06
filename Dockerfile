# 构建阶段
FROM node:20-slim AS builder
WORKDIR /app
COPY package.json ./
RUN npm install
COPY . .
RUN npm run build

# 运行阶段
FROM node:20-slim
WORKDIR /app
ENV NODE_ENV=production
COPY --from=builder /app/dist ./dist
COPY --from=builder /app/package.json ./
COPY --from=builder /app/server.ts ./
COPY --from=builder /app/Makefile ./
COPY --from=builder /app/control ./
COPY --from=builder /app/.github ./.github
RUN npm install --production && npm install -g tsx
EXPOSE 12300
CMD ["tsx", "server.ts"]
