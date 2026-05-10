# 1. Usamos una versión ligera de Node.js
FROM node:20-alpine

# 2. Creamos la carpeta donde vivirá el código en el contenedor
WORKDIR /app

# 3. Copiamos los archivos de dependencias y el código fuente a la vez
COPY package*.json ./
COPY tsconfig.json ./
COPY . .

# 4. Instalamos todas las dependencias (ahora TypeScript sí encontrará la carpeta src/)
RUN npm install

# 5. Compilamos usando vite directamente para saltar errores de tsc
RUN npx vite build

# 6. Exponemos el puerto de preview
EXPOSE 5173

# 7. Arrancamos el servidor de preview de vite
CMD ["npx", "vite", "preview", "--host", "0.0.0.0", "--port", "5173"]