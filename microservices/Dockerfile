FROM node:18-alpine

WORKDIR /usr/src/app

COPY package*.json ./

RUN npm install

COPY server.js .
ADD data /usr/src/app/data

EXPOSE 8080

CMD [ "node", "server.js" ]
