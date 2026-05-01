FROM node:lts-alpine

WORKDIR /app

COPY app/package*.json ./
RUN npm install

COPY app .
RUN npm run build

EXPOSE 3000

CMD ["node", "dist/index.js"]
