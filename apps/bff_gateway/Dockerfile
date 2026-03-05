FROM node:20-alpine AS build

WORKDIR /repo

COPY package.json package-lock.json ./
COPY apps/bff_gateway/package.json apps/bff_gateway/package.json
RUN npm ci

COPY . .
RUN npm --workspace apps/bff_gateway run build
RUN npm prune --omit=dev

FROM node:20-alpine AS runtime

WORKDIR /repo
ENV NODE_ENV=production
ENV PORT=3000

COPY --from=build /repo/package.json /repo/package-lock.json ./
COPY --from=build /repo/node_modules ./node_modules
COPY --from=build /repo/apps/bff_gateway/package.json ./apps/bff_gateway/package.json
COPY --from=build /repo/apps/bff_gateway/dist ./apps/bff_gateway/dist

EXPOSE 3000

CMD ["node", "apps/bff_gateway/dist/main.js"]
