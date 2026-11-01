FROM node:20-alpine

WORKDIR /app

# Install dependencies first so Docker can cache the layer.
COPY package.json ./
RUN npm install --omit=dev

# Copy application code.
COPY src/ ./src/
COPY migrations/ ./migrations/

EXPOSE 3000

CMD ["npm", "start"]
