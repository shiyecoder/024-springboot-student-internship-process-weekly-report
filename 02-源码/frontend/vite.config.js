import { defineConfig } from 'vite'
import vue from '@vitejs/plugin-vue'

// 前端端口固定 5175（本通道），/api 与 /uploads 代理到本通道后端 8085
export default defineConfig({
  plugins: [vue()],
  server: {
    port: 5175,
    strictPort: true,
    proxy: {
      '/api': { target: 'http://127.0.0.1:8085', changeOrigin: true },
      '/uploads': { target: 'http://127.0.0.1:8085', changeOrigin: true }
    }
  },
  build: { outDir: 'dist', chunkSizeWarningLimit: 1500 }
})
