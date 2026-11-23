FROM node:20-bookworm

# Set workdir:
WORKDIR /usr/src/app

# Install required libs for node canvas:
RUN apt-get update && apt-get install -y libuuid1 libgl1-mesa-dev

# Install deps:
COPY package*.json ./
RUN npm install --legacy-peer-deps

# Run migrations:
COPY prisma ./prisma/
RUN npx prisma generate

# Copy all files:
COPY . .

# Push schema at runtime (needs DATABASE_URL), then start:
CMD ["sh", "-c", "npx prisma db push && npm run start"]