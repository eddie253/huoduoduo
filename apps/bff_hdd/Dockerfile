FROM node:20-alpine AS build

WORKDIR /repo

COPY package.json package-lock.json ./
COPY apps/bff_hdd/package.json apps/bff_hdd/package.json
RUN npm install --legacy-peer-deps

COPY . .
RUN npm --workspace apps/bff_hdd run build

FROM node:20-alpine AS runtime

WORKDIR /repo
ENV NODE_ENV=production
ENV PORT=3000

COPY --from=build /repo/node_modules ./node_modules
COPY --from=build /repo/apps/bff_hdd/dist ./apps/bff_hdd/dist

EXPOSE 3000

CMD ["node", "apps/bff_hdd/dist/main.js"]
